/*
  stg_manual__savings
  Grain: one row per savings line (Savings ID), from the LATEST Excel file.

  The sheet is kept by hand, so we clean:
    - drop the TOTAL row and blank rows (AUD-R12 flagged them)
    - dates: real Excel dates (YYYY-MM-DD) and typed text (DD/MM/YYYY), never MM/DD
    - "Validated by Finance": Yes / yes / Y / No -> boolean
    - rows pasted twice: keep the first one in the sheet
*/
with latest_file as (
    select max(_loaded_at) as loaded_at from {{ source('raw', 'MANUAL_SAVINGS') }}
),

rows_ as (
    select s.*
    from {{ source('raw', 'MANUAL_SAVINGS') }} s
    join latest_file l on s._loaded_at = l.loaded_at
    where s._file_row_number > 1
      and s.savings_id is not null
      and upper(trim(s.savings_id)) <> 'TOTAL'
)

select
    trim(savings_id)                                         as savings_id,
    trim(event_id)                                           as event_id,
    trim(category)                                           as category_name,
    trim(supplier)                                           as supplier_name,
    try_to_number(baseline_eur, 18, 2)                       as baseline_eur,
    try_to_number(negotiated_eur, 18, 2)                     as negotiated_eur,
    try_to_number(savings_eur, 18, 2)                        as reported_savings_eur,
    coalesce(try_to_date(savings_date, 'YYYY-MM-DD'),
             try_to_date(savings_date, 'DD/MM/YYYY'))        as savings_date,
    {{ to_boolean('validated_by_finance') }}                 as is_validated_by_finance,
    trim(owner)                                              as owner_name,
    nullif(trim(comments), '')                               as comments,
    try_to_number(sheet_row)                                 as sheet_row,
    _file_name                                               as source_file,
    _loaded_at                                               as loaded_at
from rows_
qualify row_number() over (partition by trim(savings_id) order by try_to_number(sheet_row)) = 1
