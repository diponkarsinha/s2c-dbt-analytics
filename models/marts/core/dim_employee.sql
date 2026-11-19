/*
  dim_employee
  Grain: one row per procurement employee who approves contracts.
  Recursive CTE: walk approver -> manager -> manager ... up to the CPO,
  giving each person their level and full reporting line.
*/
with recursive people as (
    select approver_id as employee_id, any_value(approver_name) as employee_name,
           any_value(approver_title) as job_title, any_value(approver_manager_id) as manager_id
    from {{ ref('stg_ariba__contract_approvals') }}
    group by approver_id
),

chain as (
    select employee_id, employee_name, job_title, manager_id,
           1::number(10, 0) as org_level, employee_name::varchar(1000) as reporting_line
    from people
    where manager_id is null
       or manager_id not in (select employee_id from people)   -- top of the chain we can see

    union all

    select p.employee_id, p.employee_name, p.job_title, p.manager_id,
           c.org_level + 1, c.reporting_line || ' > ' || p.employee_name
    from people p
    join chain c on p.manager_id = c.employee_id
)

select * from chain
