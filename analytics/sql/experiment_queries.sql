SELECT 
    acquisition_channel,
    a_total_users,
    b_total_users,
    relative_lift_pct,
    z_score,
    is_statistically_significant
FROM rpt_experiment_results_by_channel
WHERE conversion_event = 'upgrade'
    AND acquisition_channel = 'paid_search';

SELECT 
    acquisition_channel,
    experiment_variant,
    COUNT(*) as users,
    MIN(assigned_at) as first_assignment,
    MAX(assigned_at) as last_assignment
FROM fct_experiments_assignments
GROUP BY acquisition_channel, experiment_variant
ORDER BY acquisition_channel, experiment_variant;