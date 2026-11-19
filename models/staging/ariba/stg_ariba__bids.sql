/*
  stg_ariba__bids
  Grain: one row per bid per round per event.
  Second-level FLATTEN (events -> bids). Some bids appear twice in the
  source array, so we de-duplicate on event + bid + round.
*/
with bids as (
    select
        ev.event_id,
        b.value as bid
    from {{ ref('stg_ariba__sourcing_events') }} ev,
         lateral flatten(input => ev.bids_json) b
)

select
    event_id,
    bid:bidId::string                                     as bid_id,
    bid:round::number                                     as bid_round,
    event_id || '|' || bid:bidId::string || '|' || bid:round::string as bid_key,
    bid:supplier:aribaId::string                          as ariba_supplier_id,
    bid:supplier:name::string                             as supplier_name,
    upper(replace(bid:supplier:vatNumber::string, ' ', '')) as vat_number,
    bid:bidAmount::number(18, 2)                          as bid_amount,
    bid:currency::string                                  as currency,
    try_to_timestamp_ntz(bid:submittedAt::string)         as submitted_at
from bids
qualify row_number() over (partition by bid_key order by submitted_at) = 1
