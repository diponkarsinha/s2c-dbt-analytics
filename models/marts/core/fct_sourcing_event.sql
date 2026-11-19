/*
  fct_sourcing_event
  Grain: one row per sourcing event.
  Competition (number of bidders), price outcome and timing in one place.
*/
with bid_stats as (
    select
        event_id,
        count(distinct ariba_supplier_id)                    as bidder_count,
        count(*)                                             as bid_count,
        max(bid_round)                                       as round_count,
        min(bid_amount)                                      as lowest_bid_amount
    from {{ ref('stg_ariba__bids') }}
    group by event_id
)

select
    e.event_id,
    e.event_type,
    e.event_status,
    e.request_id,
    e.category_id,
    m.golden_supplier_id                                     as awarded_supplier_id,
    e.created_at::date                                       as created_date,
    e.opened_at::date                                        as opened_date,
    e.closed_at::date                                        as closed_date,
    e.awarded_at::date                                       as awarded_date,
    e.event_status = 'Completed' and e.awarded_at is null    as is_missing_award_date,
    coalesce(b.bidder_count, 0)                              as bidder_count,
    coalesce(b.bid_count, 0)                                 as bid_count,
    coalesce(b.round_count, 0)                               as round_count,
    coalesce(b.bidder_count, 0) = 1                          as is_single_source,
    e.baseline_amount,
    b.lowest_bid_amount,
    e.awarded_amount,
    e.baseline_amount - e.awarded_amount                     as calculated_savings_eur,
    round(100 * (e.baseline_amount - e.awarded_amount) / nullif(e.baseline_amount, 0), 2) as savings_pct,
    datediff(day, e.opened_at, e.closed_at)                  as days_open
from {{ ref('stg_ariba__sourcing_events') }} e
left join bid_stats b on b.event_id = e.event_id
left join {{ ref('int_supplier_mapping') }} m on m.ariba_supplier_id = e.awarded_ariba_supplier_id
