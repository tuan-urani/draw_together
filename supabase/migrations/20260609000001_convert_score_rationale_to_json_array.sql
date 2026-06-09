alter table public.scores
  alter column rationale type jsonb
  using case
    when rationale is null then null
    else jsonb_build_array(rationale)
  end;

alter table public.scores
  drop constraint if exists scores_rationale_array_check;

alter table public.scores
  add constraint scores_rationale_array_check
    check (rationale is null or jsonb_typeof(rationale) = 'array');

comment on column public.scores.rationale is
  'AI score rationale as a JSON array of concise displayable bullet strings.';
