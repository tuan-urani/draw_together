alter table public.scores
  add column if not exists rationale_localized jsonb;

comment on column public.scores.rationale_localized is
  'AI score rationale as a JSON object keyed by locale codes.';
