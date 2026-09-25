-- =================================================================================
-- 1. Customers & Features
-- =================================================================================

CREATE TABLE customers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  phone_number TEXT NOT NULL UNIQUE,
  business_name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'expired')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE feature_catalog (
  id TEXT PRIMARY KEY, -- e.g., 'cashier', 'treasury', 'accounting', 'inventory'
  name TEXT NOT NULL,
  monthly_price NUMERIC(10, 2) NOT NULL DEFAULT 0.0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =================================================================================
-- 2. Subscriptions
-- =================================================================================

CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  active_feature_ids TEXT[] NOT NULL DEFAULT '{}',
  max_devices INT NOT NULL DEFAULT 1,
  billing_cycle_start_day INT NOT NULL DEFAULT 1 CHECK (billing_cycle_start_day >= 1 AND billing_cycle_start_day <= 31),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'cancelled')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =================================================================================
-- 3. Billing (Ledger System - Append Only)
-- =================================================================================

CREATE TABLE invoices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  amount_due NUMERIC(10, 2) NOT NULL DEFAULT 0.0,
  issued_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  amount NUMERIC(10, 2) NOT NULL,
  paid_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  note TEXT,
  applied_to_invoice_id UUID REFERENCES invoices(id) ON DELETE SET NULL
);

-- =================================================================================
-- 4. Activation Requests & Licensing
-- =================================================================================

CREATE TABLE activation_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
  device_fingerprint TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  decided_at TIMESTAMPTZ,
  UNIQUE(subscription_id, device_fingerprint) -- Prevent duplicate pending requests for the same device
);

CREATE TABLE active_devices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
  device_fingerprint TEXT NOT NULL,
  activated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(subscription_id, device_fingerprint)
);

-- =================================================================================
-- 5. Audit Logs
-- =================================================================================

CREATE TABLE plan_change_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
  changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  old_features TEXT[] NOT NULL DEFAULT '{}',
  new_features TEXT[] NOT NULL DEFAULT '{}',
  note TEXT
);

-- =================================================================================
-- Security & Realtime Policies
-- =================================================================================
-- We want the admin app to have full access (when authenticated), 
-- but the Taj client app needs to insert into activation_requests anonymously or via a simple anon key.

-- Enable Row Level Security (RLS)
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE feature_catalog ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE activation_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE active_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE plan_change_logs ENABLE ROW LEVEL SECURITY;

-- 1. Admin Access Policy (Assuming your Admin app logs in with Supabase Auth)
-- This creates a blanket policy for authenticated users (You, the Admin)
CREATE POLICY "Allow all for authenticated admins" ON customers FOR ALL TO authenticated USING (true);
CREATE POLICY "Allow all for authenticated admins" ON feature_catalog FOR ALL TO authenticated USING (true);
CREATE POLICY "Allow all for authenticated admins" ON subscriptions FOR ALL TO authenticated USING (true);
CREATE POLICY "Allow all for authenticated admins" ON invoices FOR ALL TO authenticated USING (true);
CREATE POLICY "Allow all for authenticated admins" ON payments FOR ALL TO authenticated USING (true);
CREATE POLICY "Allow all for authenticated admins" ON activation_requests FOR ALL TO authenticated USING (true);
CREATE POLICY "Allow all for authenticated admins" ON active_devices FOR ALL TO authenticated USING (true);
CREATE POLICY "Allow all for authenticated admins" ON plan_change_logs FOR ALL TO authenticated USING (true);

-- 2. Client App Access Policy
-- The client app (Taj POS) needs to be able to:
--   a) Insert activation requests.
--   b) Read its own activation request status.
-- Using the 'anon' role which the app uses with its Anon Key.

CREATE POLICY "Allow anon to insert activation requests" ON activation_requests 
  FOR INSERT TO anon 
  WITH CHECK (true);

CREATE POLICY "Allow anon to select their own activation requests" ON activation_requests 
  FOR SELECT TO anon 
  USING (true); -- In a strict production environment, limit this to device_fingerprint

-- Enable Realtime for activation_requests (so Admin App gets notified instantly)
-- Go to Supabase Dashboard -> Database -> Replication -> Enable for 'activation_requests'
-- OR run:
alter publication supabase_realtime add table activation_requests;
