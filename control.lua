function log_data(tick,line)
    game.write_file("stats_mod/factorio." .. tick .. ".csv", line .. "\n", false)   
 end

 local statistics = {
    "item_production_statistics",
    "fluid_production_statistics",
    "kill_count_statistics",
    "entity_build_count_statistics",
}

function merge_line(tick,force_name, stat_name, prod_type, item, amount) 
    line = tick .. "," .. force_name .. "," .. stat_name .. "," .. prod_type .. "," .. item .. "," .. amount
    return line
end
 
 script.on_nth_tick(60, -- every second
 function(event)

    data_to_write = ""

   for k, force in pairs(game.forces) do

    for _, statName in pairs(statistics) do

        for item, amount in pairs(force[statName].input_counts) do
            data_to_write = data_to_write .. merge_line(
                game.tick, force.name, statName,"input",item, amount
            ) .. "\n"
        end

        for item, amount in pairs(force[statName].output_counts) do
            data_to_write = data_to_write .. merge_line(
                game.tick, force.name, statName,"output",item, amount
            ) .. "\n"
        end
    

     end
   end 
   log_data(game.tick,data_to_write)
 end)