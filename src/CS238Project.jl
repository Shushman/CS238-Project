__precompile__()
module CS238Project

using DataStructures
using Distributions
using ParticleFilters, POMCPOW
importall POMDPs

# sensors.jl
export
    Sensor,
    LineSensor,
    CircularSensor,
    sense,
    change_confidence,
    update_bel_map_mdp,
    consume_energy,
    energy_usage_likelihood

# uav_pomdp.jl - POMDP
export
    UAVpomdp,
    State,
    Observation,
    BeliefState,
    generate_o,
    generate_s,
    reward,
    reward_no_heuristic,
    isterminal,
    update_belief,
    initial_belief_state

# uav_pomdp - Belief MDP
export
    UAVBeliefMDP,
    MDPState,
    generate_sr,
    next_state_reward_true

# # ground_truth.jl - simulator
# export
#     SimulatorState,
#     first_update_simulator,
#     update_simulator,
#     freeze_simulator,
#     optimal_action_given_information,
#     choose_information_action,
#     greedy_information_action




abstract type Sensor end


include("sensors.jl")
include("uav_pomdp.jl")


end #module