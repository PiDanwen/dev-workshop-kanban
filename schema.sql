-- ============================================================
-- 开发工坊 · 看板任务面板 — 数据库建表 & 种子数据
-- 适用: Supabase (PostgreSQL)
-- 使用方式: 在 Supabase SQL Editor 中全选执行
-- ============================================================

-- 1. 建表
CREATE TABLE IF NOT EXISTS tasks (
  id            SERIAL PRIMARY KEY,
  title         TEXT NOT NULL,
  description   TEXT DEFAULT '',
  priority      TEXT CHECK (priority IN ('P0','P1','P2','P3')) DEFAULT 'P2',
  category      TEXT CHECK (category IN ('前端','后端','设计','缺陷','需求')) NOT NULL,
  assignee      TEXT NOT NULL,
  due_date      DATE,
  column_id     TEXT CHECK (column_id IN ('backlog','todo','doing','review','done')) DEFAULT 'backlog',
  sort_order    INTEGER NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now()
);

-- 2. 自动更新 updated_at 触发器
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_timestamp ON tasks;
CREATE TRIGGER set_timestamp
  BEFORE UPDATE ON tasks
  FOR EACH ROW EXECUTE FUNCTION update_modified_column();

-- 3. 排序索引
CREATE INDEX IF NOT EXISTS idx_tasks_column_sort ON tasks (column_id, sort_order);

-- 4. 启用 Realtime（多端实时同步）
-- 注意：Supabase 新项目默认已启用 Realtime，如报错"already member"可忽略
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE tasks;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- 5. 启用行级安全 (RLS) 并开放读写（开发阶段）
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all for now" ON tasks;
CREATE POLICY "Allow all for now" ON tasks
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- ============================================================
-- 6. 种子数据（18 条任务）
-- ============================================================
INSERT INTO tasks (title, description, priority, category, assignee, due_date, column_id, sort_order) VALUES
('支付接口超时重试机制',   '对接三方支付时网络抖动导致偶发失败，需引入指数退避重试与熔断保护。',                       'P0', '后端', 'PiDanwen', '2025-09-08', 'doing',    1),
('移动端白屏崩溃缺陷',     '低端安卓机型进入直播间偶发白屏，疑似内存溢出，需复现并定位根因。',                       'P0', '缺陷', 'PiDanwen', '2025-09-05', 'review',   1),
('首屏加载速度优化',       '核心页面 LCP 超过 3.5s，需做资源分包、图片懒加载与预连接优化。',                       'P0', '前端', 'PiDanwen', '2025-09-12', 'doing',    2),
('订单状态流转异常',       '退款中订单被错误回滚为已支付，资金对账出现差异，需紧急修复。',                           'P0', '缺陷', 'PiDanwen', '2025-09-06', 'review',   2),
('用户画像标签系统需求评审','梳理标签维度与更新频率，明确实时与离线两套链路的边界。',                               'P2', '需求', 'PiDanwen', '2025-10-02', 'backlog',  1),
('商品搜索性能优化',       '大促期间搜索 RT 飙升，需增加缓存层并优化 ES 查询语句。',                               'P1', '后端', 'PiDanwen', '2025-09-20', 'doing',    3),
('暗色模式适配',           '全站支持暗色主题，统一色彩 token 并保证对比度达标。',                                   'P2', '前端', 'PiDanwen', '2025-08-28', 'done',     1),
('消息推送服务限流',       '营销推送峰值触发通道限流，需按用户分层做平滑下发。',                                   'P1', '后端', 'PiDanwen', '2025-09-18', 'doing',    4),
('引导页插画资源产出',     '新版新手引导需要 4 张场景插画，风格与品牌视觉保持一致。',                               'P3', '设计', 'PiDanwen', '2025-10-10', 'backlog',  2),
('会员体系升级需求拆解',   '将成长值与权益解耦，支持按城市配置差异化会员特权。',                                   'P1', '需求', 'PiDanwen', '2025-09-25', 'backlog',  3),
('登录页表单校验优化',     '弱网环境下校验提示延迟，需优化校验时序与错误文案可读性。',                               'P1', '前端', 'PiDanwen', '2025-09-15', 'todo',     1),
('首页视觉改版设计稿',     '重构信息层级，强化核心转化入口，输出高保真与交互说明。',                                 'P2', '设计', 'PiDanwen', '2025-09-22', 'todo',     2),
('数据看板交互原型',       '为运营搭建自助分析原型，支持维度拖拽与图表联动筛选。',                                   'P2', '设计', 'PiDanwen', '2025-10-05', 'todo',     3),
('数据库慢查询治理',       '梳理 Top20 慢 SQL，补充缺失索引并推动读写分离改造。',                                   'P1', '后端', 'PiDanwen', '2025-09-19', 'doing',    5),
('无障碍访问兼容性修复',   '键盘可达性与读屏兼容性不达标，需补齐 ARIA 与焦点管理。',                               'P2', '缺陷', 'PiDanwen', '2025-09-28', 'review',   3),
('优惠券核销接口重构',     '将核销逻辑下沉为独立服务，支持多门店并发核销与冲正。',                                   'P1', '后端', 'PiDanwen', '2025-08-26', 'done',     2),
('组件库文档站点建设',     '搭建组件演示与 API 文档站，沉淀设计规范与使用示例。',                                   'P3', '前端', 'PiDanwen', '2025-10-15', 'backlog',  4),
('用户反馈收集问卷设计',   '设计 NPS 与功能满意度问卷，规划回收与分层分析口径。',                                   'P3', '需求', 'PiDanwen', '2025-10-20', 'backlog',  5);
