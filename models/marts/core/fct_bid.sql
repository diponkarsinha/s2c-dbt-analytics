/*
  fct_bid
  Grain: one row per bid per round.
  bid_rank_in_round: 1 = cheapest bid in that round (window function).
*/
select
    b.bid_key,
    b.event_id,
    b.bid_id,
    b.bid_round,
    m.golden_supplier_id                                      as supplier_id,
    b.ariba_supplier_id,
    m.is_matched                                              as is_supplier_matched,
    b.bid_amount,
    b.submitted_at,
    rank() over (partition by b.event_id, b.bid_round order by b.bid_amount) as bid_rank_in_round,
    b.bid_amount - lag(b.bid_amount) over (
        partition by b.event_id, b.ariba_supplier_id order by b.bid_round) as change_vs_previous_round
from {{ ref('stg_ariba__bids') }} b
left join {{ ref('int_supplier_mapping') }} m on m.ariba_supplier_id = b.ariba_supplier_id
