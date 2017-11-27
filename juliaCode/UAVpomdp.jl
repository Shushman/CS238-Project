importall POMDPs
using ParticleFilters, POMCPOW
using Distributions
include("Sensors.jl")

#################################
# Define state and action space #
#################################

# TODO : Work with StaticArrays for location?
struct State
    location::Array{Int64,1} # (row,column)
    total_battery_used::Float64
    world_map::BitArray
end

struct Observation
    obs_location::Array{Int64,1}
    obs_battery_used::Float64
    obs_world_map::Array{Tuple{Bool,Float64},2}
end

struct BeliefState
    bel_location::Array{Int64,1}
    bel_battery_used::Array{Float64,1}
    bel_world_map::Array{Float64,2}
end

type UAVpomdp <: POMDPs.POMDP{State,Int64,Observation}
    map_size::Int64
    true_map::BitArray{2}
    start_coords::Array{Int64,1}
    goal_coords::Array{Int64,1}
    sensor_set::Array{Sensor,1}
    reward_lambdas::Array{Float64,1}
end

#Define actions by ints
NUM_SENSORS = 5
NUM_MOVEMENTS = 4

SENSORS = 1:NUM_SENSORS
MOVEMENTS = NUM_SENSORS+1:NUM_SENSORS+NUM_MOVEMENTS

@enum MOVEMENT_STRING RIGHT=NUM_SENSORS+1 LEFT=NUM_SENSORS+2 UP=NUM_SENSORS+3 DOWN=NUM_SENSORS+4

# The observation from a state is just the map of th
function generate_o(p::UAVpomdp, s::State, a::Int64, sp::State, rng::MersenneTwister)
    
    obs_loc = sp.location
    obs_batt_used = sp.total_battery_used - s.total_battery_used
    obs_map = Array{Tuple{Bool,Float64}}(p.map_size, p.map_size)

    fill!(obs_map,(false,0.5))

    # Should have an enum set for movements and sensors
    if a in MOVEMENTS
        # Just observe current cell with full conf
        obs_map[sp.location[1],sp.location[2]] = ( sp.world_map[sp.location[1],sp.location[2]], 1.0 )
    else
        # action is in SENSORS
        # Need each sensor to implement sense method
        # with arguments (true grid, agent coords) and returns the matrix of obs-conf. Will explain
        # This action is a hindsight thing so does not consume energy
        # TODO : implement sense()
        obs_map = p.sensor_set[a].sense(sp.world_map, sp.location, rng)
    end

    return Observation(obs_loc,obs_batt_used,obs_map)
end

function generate_s(p::UAVpomdp, s::State, a::Int64, rng::MersenneTwister)

    map_size = size(s.world_map,1)
    # Begin by copying over values
    new_loc = [s.location[1], s.location[2]]
    new_batt = s.total_battery_used
    new_map = s.world_map

    if a in MOVEMENTS
        if a == Int(RIGHT)
            # Increase column by one
            new_loc[2] += 1
        elseif a == Int(LEFT)
            # Decrease column by one
            new_loc[2] -= 1
        elseif a == Int(UP)
            new_loc[1] -= 1
        else
            new_loc[1] += 1
        end

        if new_loc[1] < 1 || new_loc[1] > map_size || new_loc[2] < 1 || new_loc[2] > map_size
            # Just set to old location
            new_loc = [s.location[1], s.location[2]]
        end
        new_batt += 1
    else
        # The only change is to battery
        new_batt += p.sensor_set[a].consumeEnergy(rng)
    end

    return State(new_loc,new_batt,new_map)
end

# One step reward for various situations
function reward(p::UAVpomdp, s::State, a::Int64, sp::State)

    # TODO : Add large positive reward for reaching goal_coords?

    # Component 1 - movement
    # 0 if no movement
    manhattan_distance = abs(s.location[1] - sp.location[1]) + abs(s.location[2]-sp.location[2])
    cost_comp1 = p.reward_lambdas[1] * manhattan_distance

<<<<<<< HEAD
    if manhattan_distance == 0 && a in MOVEMENTS
        cost_comp1 = p.reward_lambdas[1]
    end

    if sp.location[1] == 0 || sp.location[1] > p.map_size || sp.location[2] == 0 || sp.location[2] > p.map_size
        cost_comp1 += 100
=======
    if sp.location[1] == 0 || sp.location[1] > p.map_size || sp.location[2] == 0 || sp.location[2] > p.map_size
        cost_comp1 = p.reward_lambdas[1] * 10.0
>>>>>>> 3064de21eb0c64fd7ce7e7d214b1bc3659c74a51
    end

    goal_loc = p.goal_coords
    goal_l1_dist = abs(goal_loc[1] - sp.location[1]) + abs(goal_loc[2]-sp.location[2])
<<<<<<< HEAD
    
    cost_comp1 += 1.5*p.reward_lambdas[1] * goal_l1_dist
=======
    cost_comp1 += (p.reward_lambdas[1]/10.0) * goal_l1_dist
>>>>>>> 3064de21eb0c64fd7ce7e7d214b1bc3659c74a51

    # Component 2 - one-step energy usage
    # 0 if no sensing action done
    cost_comp2 = p.reward_lambdas[2] * (sp.total_battery_used - s.total_battery_used)

    # Component 3 - If in no-fly-zone
    # true means no-fly-zone : additional cost
    cost_comp3 = p.reward_lambdas[3] * Int(p.true_map[sp.location[1],sp.location[2]])

    reward = -(cost_comp1 + cost_comp2 + cost_comp3)

    if isterminal(p, sp)
        reward += 1000.0
    end

    return reward
end

###############################################
# Define POMDP struct and initialize instance #
###############################################

# type UAVpomdp <: POMDPs.POMDP{State,Int64,Observation}
#     map_size::Int64
#     true_map::BitArray{2}
#     start_coords::Array{Int64,1}
#     goal_coords::Array{Int64,1}
#     sensor_set::Array{Sensor,1}
#     reward_lambdas::Array{Float64}
# end

# These seem to be needed by POMCP
# TODO : See if you need discount < 1.0 for POMCP properties
discount(::UAVpomdp) = 1.0
isterminal(p::UAVpomdp,s::State) = (s.location == p.goal_coords)# || s.total_battery_used >= 100);
actions(p::UAVpomdp) = 1:NUM_SENSORS+NUM_MOVEMENTS
n_actions(p::UAVpomdp) = NUM_SENSORS+NUM_MOVEMENTS

# Default parameters: map_size is 20 x 20; true_map is all cells true and true_battery_left is 100
# TODO : Cost of NFZ should be HIGH to encourage sensor usage
# sensors = [LineSensor([0,1]),LineSensor([1,0]),LineSensor([0,-1]),LineSensor([-1,0]),CircularSensor()]
# pomdp = UAVpomdp(40, falses(40,40), [1,1], [40,40], sensors, [1.0,1.0,1.0])

# Initial distribution with belief state
# Put in some default variables here?
function initial_belief_state(p::UAVpomdp)
    bel_location = [1,1]
    # TODO : Can't have 0.0 std for normal. Shouldn't matter anyway but just
    # make sure it never gets positive reward for negative battery_used
    bel_batt = [0.0,eps()]
    bel_world_map = 0.5*ones(p.map_size,p.map_size)
    bel_world_map[1,1] = 0.0 # 0% chance of NFZ

    return BeliefState(bel_location, bel_batt, bel_world_map)
end

function logit(x::Float64)

    return log(x ./ (1.0 .+ x))

end

# generate_s will just use the generate_s of the POMDP
# ParticleFilters - need observation weight function
# Also need a ParticleGenerator?
function ParticleFilters.obs_weight(p::UAVpomdp, s::State, a::Int64, sp::State, o::Observation)

    logweight = 0.0
    #agreement_weight = 5.0

    # If movement only check that cell of current location is equal to true
    if a in MOVEMENTS
        logweight += log(p.true_map[sp.location[1], sp.location[2]] == o.obs_world_map[sp.location[1], sp.location[2]][1])
    else
        # Loop through cells and update weight based on sensor agreement
        for i = 1 : p.map_size
            for j = 1 : p.map_size

                if o.obs_world_map[i,j][1] == sp.world_map[i,j]
                    logweight += logit(o.obs_world_map[i,j][2])
                else
                    logweight += logit(1-o.obs_world_map[i,j][2])
                end

                # # TODO : The disagreement will never happen as per our definition - see if that affects anything
                # if o.obs_world_map[i,j][1] == sp.world_map[i,j]
                #     logweight += o.obs_world_map[i,j][2]*log(agreement_weight)
                # else
                #     logweight -= o.obs_world_map[i,j][2]*log(agreement_weight)
                # end
            end
        end

        logweight += log(p.sensor_set[a].energyUsageLikelihood(o.obs_battery_used))
    end

    return exp(logweight)
end

# The explicit belief updated to be used by the outer Loop
function update_belief(p::UAVpomdp, b::BeliefState, a::Int64, o::Observation)

    # New belief location is just the observed location
    # Initialize battery dist with old normal
    # Initialize obs_map with old map
    new_bel_loc = o.obs_location
    new_batt_used = b.bel_battery_used
    new_bel_map = deepcopy(b.bel_world_map)

    # If action is movement, only the 
    # bel_map for the new cell changes
    if a in MOVEMENTS
        # Implicit conversion from bool to double
        new_bel_map[o.obs_location[1],o.obs_location[2]] = o.obs_world_map[o.obs_location[1],o.obs_location[2]][1]
    else
        # Action is a sensor usage
        # Update battery gaussians
        sensor_mean_std = p.sensor_set[a].energySpec
        new_batt_used = [b.bel_battery_used[1] + sensor_mean_std[1] , sqrt(b.bel_battery_used[2]^2 + sensor_mean_std[2]^2)]

        # Now update grid
        for i = 1 : p.map_size
            for j = 1 : p.map_size

                if o.obs_world_map[i,j][2] > 0.5 #0.0
                    # confval = 0.0
                    # weightcoeff = 1.0 #TODO - This weights the new observation vs current
                    
                    # # Do a weighted sum of old and new estimates
                    # if o.obs_world_map[i,j][1] == true
                    #     confval = (b.bel_world_map[i,j] + 1.0*weightcoeff)/(1.0 + o.obs_world_map[i,j][2]*weightcoeff)
                    # else
                    #     confval = (b.bel_world_map[i,j])/(1.0 + o.obs_world_map[i,j][2]*weightcoeff)
                    # end

                    #perform a bayesian update
                    if o.obs_world_map[i,j][1] == true
                        top = o.obs_world_map[i,j][2]*b.bel_world_map[i,j]
                        bottom = top + (1.0 - o.obs_world_map[i,j][2])*(1.0 - b.bel_world_map[i,j])
                        new_bel_map[i,j] = top ./ bottom
                    else
                        top = (1-o.obs_world_map[i,j][2])*b.bel_world_map[i,j]
                        bottom = top + o.obs_world_map[i,j][2]*(1-b.bel_world_map[i,j])
                        new_bel_map[i,j] = top ./ bottom #1 - top ./ bottom
                    end
                end
            end
        end
    end

    return BeliefState(new_bel_loc, new_batt_used, new_bel_map)
end


# A sampler for the belief state
function rand(rng::AbstractRNG, b::BeliefState)

    state_loc = [b.bel_location[1], b.bel_location[2]]
    state_bat = rand(rng,b.bel_battery_used)
    map_size = size(b.bel_world_map,1)

    # Now initialize grid
    # Sample a random number for each cell and assign cell state based on result
    state_map = BitArray{2}(map_size,map_size)
    for i = 1 : map_size
        for j = 1 : map_size

            randval = rand(rng)
            if randval < b.bel_world_map[i,j]
                state_map[i,j] = true
            else
                state_map[i,j] = false
            end
        end
    end

    return State(state_loc,state_bat,state_map)
end

