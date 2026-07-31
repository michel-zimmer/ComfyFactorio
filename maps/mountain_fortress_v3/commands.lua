local Public = require 'maps.mountain_fortress_v3.table'
local Task = require 'utils.task_token'
local Server = require 'utils.server'
local Collapse = require 'modules.collapse'
local WD = require 'modules.wave_defense.table'
local Discord = require 'utils.discord_handler'
local Commands = require 'utils.commands'
local Color = require 'utils.color_presets'
local Difficulty = require 'modules.difficulty_vote_by_amount'
local mapkeeper = '[color=blue]Mapkeeper:[/color]'
local CommandColor = { r = 0.98, g = 0.66, b = 0.22 }


local gather_time_token =
    Task.register(
        function (event)
            local stateful = Public.get_stateful()
            if event.instant_win then
                stateful.objectives_completed_count = stateful.tasks_required_to_win
                stateful.collection.gather_time_timer = 0
                stateful.collection.gather_time = 0
                stateful.collection.survive_for = 0
                stateful.collection.survive_for_timer = 0
            else
                stateful.collection.gather_time_timer = 0
            end
        end
    )

Commands.new('scenario', 'Usable only for admins - controls the scenario!')
    :require_admin()
    :require_validation()
    :add_parameter('restart/shutdown/reset/restartnow', false, 'string')
    :callback(
        function (player, action)
            local this = Public.get()

            if action == 'restart' or action == 'shutdown' or action == 'reset' or action == 'restartnow' then
                goto continue
            else
                player.print('Invalid action.')
                return false
            end

            ::continue::

            if action == 'restart' then
                if this.restart then
                    this.reset_are_you_sure = nil
                    this.restart = false
                    this.soft_reset = true
                    Discord.send_notification(
                        {
                            title = "Soft-reset enabled",
                            description = player.name .. ' has enabled soft-reset!',
                            color = "info",
                            fields =
                            {
                                {
                                    title = "Server",
                                    description = Public.discord_name,
                                    inline = "false"
                                }
                            }
                        })
                    player.print('Soft-reset is enabled.')
                else
                    this.reset_are_you_sure = nil
                    this.restart = true
                    this.soft_reset = false
                    if this.shutdown then
                        this.shutdown = false
                    end
                    Discord.send_notification(
                        {
                            title = "Soft-reset disabled",
                            description = player.name .. ' has disabled soft-reset! Restart will happen from scenario.',
                            color = "warning",
                            fields =
                            {
                                {
                                    title = "Server",
                                    description = Public.discord_name,
                                    inline = "false"
                                }
                            }
                        })
                    player.print('Soft-reset is disabled! Server will restart from scenario to load new changes.')
                end
            elseif action == 'restartnow' then
                this.reset_are_you_sure = nil
                Server.start_scenario('Mountain_Fortress_v3')
                Discord.send_notification(
                    {
                        title = "Scenario restarted",
                        description = player.name .. ' restarted the scenario.',
                        color = "success",
                        fields =
                        {
                            {
                                title = "Server",
                                description = Public.discord_name,
                                inline = "false"
                            }
                        }
                    })
                player.print('Restarted the scenario.')
            elseif action == 'shutdown' then
                if this.shutdown then
                    this.reset_are_you_sure = nil
                    this.shutdown = false
                    this.soft_reset = true
                    Discord.send_notification(
                        {
                            title = "Soft-reset enabled",
                            description = player.name .. ' has enabled soft-reset. Server will NOT shutdown!',
                            color = "success",
                            fields =
                            {
                                {
                                    title = "Server",
                                    description = Public.discord_name,
                                    inline = "false"
                                }
                            }
                        })

                    player.print('Soft-reset is enabled.')
                else
                    this.reset_are_you_sure = nil
                    this.shutdown = true
                    this.soft_reset = false
                    if this.restart then
                        this.restart = false
                    end

                    Discord.send_notification(
                        {
                            title = "Soft-reset disabled",
                            description = player.name .. ' has disabled soft-reset. Server will shutdown!',
                            color = "warning",
                            fields =
                            {
                                {
                                    title = "Server",
                                    description = Public.discord_name,
                                    inline = "false"
                                }
                            }
                        })
                    player.print('Soft-reset is disabled! Server will shutdown.')
                end
            elseif action == 'reset' then
                this.reset_are_you_sure = nil
                if player and player.valid then
                    game.print(mapkeeper .. ' ' .. player.name .. ', has reset the game!',
                        { color = CommandColor })
                    Discord.send_notification(
                        {
                            title = "Game reset",
                            description = player.name .. ' has reset the game!',
                            color = "success",
                            fields =
                            {
                                {
                                    title = "Server",
                                    description = Public.discord_name,
                                    inline = "false"
                                }
                            }
                        })
                else
                    game.print(mapkeeper .. ' server, has reset the game!', { color = CommandColor })
                    Discord.send_notification(
                        {
                            title = "Game reset",
                            description = 'Server has reset the game!',
                            color = "success",
                            fields =
                            {
                                {
                                    title = "Server",
                                    description = Public.discord_name,
                                    inline = "false"
                                }
                            }
                        })
                end
                local current_task = Public.get('current_task')
                Public.set_task(current_task.default_task)
                player.print('Game has been reset!')
            end
        end
    )

Commands.new('mtn_set_queue_speed', 'Usable only for admins - sets the queue speed of this map!')
    :require_admin()
    :require_validation()
    :add_parameter('speed', true, 'number')
    :callback(
        function (player, speed)
            Task.set_queue_speed(speed)
            Discord.send_notification(
                {
                    title = "Queue speed set",
                    description = player.name .. ' set the queue speed to: ' .. speed,
                    color = "success",
                    fields =
                    {
                        {
                            title = "Server",
                            description = Public.discord_name,
                            inline = "false"
                        }
                    }
                })
            player.print('Queue speed set to: ' .. speed)
        end
    )

Commands.new('mtn_complete_quests', 'Usable only for admins - completes all the quests!')
    :require_admin()
    :require_validation()
    :add_parameter('no_grace', true, 'boolean')
    :add_parameter('instant_win', true, 'boolean')
    :callback(
        function (player, no_grace, instant_win)
            Discord.send_notification(
                {
                    title = "Quests completed",
                    description = player.name .. ' completed all the quest via command.',
                    color = "success",
                    fields =
                    {
                        {
                            title = "Server",
                            description = Public.discord_name,
                            inline = "false"
                        }
                    }
                })
            local stateful = Public.get_stateful()
            stateful.objectives_completed_count = stateful.tasks_required_to_win
            if no_grace and not instant_win then
                Task.set_timeout_in_ticks(20, gather_time_token, {})
                game.print(mapkeeper .. player.name .. ', has forced completed all quests with no grace period!', { color = CommandColor })
            elseif instant_win then
                Task.set_timeout_in_ticks(100, gather_time_token, { instant_win = true })
                Task.set_timeout_in_ticks(120, gather_time_token, { instant_win = true })
                game.print(mapkeeper .. player.name .. ', has forced completed all quests with instant win!', { color = CommandColor })
            end
            player.print('Quests completed.')
        end
    )

Commands.new('mtn_reverse_map', 'Usable only for admins - reverses the map!')
    :require_admin()
    :require_validation()
    :callback(
        function (player)
            local reversed = Public.get_stateful_settings('reversed')
            Public.set_stateful_settings('reversed', not reversed)
            Discord.send_notification(
                {
                    title = "Map reversed",
                    description = player.name .. ' reversed the map.',
                    color = "success",
                    fields =
                    {
                        {
                            title = "Server",
                            description = Public.discord_name,
                            inline = "false"
                        }
                    }
                })
            local current_task = Public.get('current_task')
            Public.set_task(current_task.default_task)
            game.print(mapkeeper .. player.name .. ', has reverse the map and reset the game!',
                { color = CommandColor })
            player.print('Map reversed.')
        end
    )

Commands.new('mtn_disable_biters', 'Usable only for admins - disables wave defense!')
    :require_admin()
    :require_validation()
    :callback(
        function (player)
            local tbl = WD.get()

            if not tbl.game_lost then
                Discord.send_notification(
                    {
                        title = "Wave defense disabled",
                        description = player.name .. ' disabled the wave defense module.',
                        color = "success",
                        fields =
                        {
                            {
                                title = "Server",
                                description = Public.discord_name,
                                inline = "false"
                            }
                        }
                    })
                game.print(mapkeeper .. ' ' .. player.name .. ', has disabled the wave_defense module!',
                    { color = CommandColor })
                tbl.game_lost = true
            else
                Discord.send_notification(
                    {
                        title = "Wave defense enabled",
                        description = player.name .. ' enabled the wave defense module.',
                        color = "success",
                        fields =
                        {
                            {
                                title = "Server",
                                description = Public.discord_name,
                                inline = "false"
                            }
                        }
                    })
                game.print(mapkeeper .. ' ' .. player.name .. ', has enabled the wave_defense module!',
                    { color = CommandColor })
                tbl.game_lost = false
            end
        end
    )

Commands.new('mtn_toggle_darkness', 'Usable only for admins - toggles the darkness!')
    :require_admin()
    :require_validation()
    :callback(
        function (player)
            local darkness = Public.get_stateful_settings('darkness')
            local active_surface_index = Public.get('active_surface_index')
            local surface = game.surfaces[active_surface_index]
            if not surface then
                return
            end
            if darkness then
                Public.set_stateful_settings('darkness', false)
                game.print('Darkness is now disabled!')
                Discord.send_notification(
                    {
                        title = "Surface darkness disabled",
                        description = player.name .. ' disabled surface darkness.',
                        color = "success",
                        fields =
                        {
                            {
                                title = "Server",
                                description = Public.discord_name,
                                inline = "false"
                            }
                        }
                    })
                surface.brightness_visual_weights = { a = 1, b = 0, g = 0, r = 0 }
            else
                Public.set_stateful_settings('darkness', true)
                game.print('Darkness is now enabled!')
                Discord.send_notification(
                    {
                        title = "Surface darkness enabled",
                        description = player.name .. ' enabled surface darkness.',
                        color = "success",
                        fields =
                        {
                            {
                                title = "Server",
                                description = Public.discord_name,
                                inline = "false"
                            }
                        }
                    })
                surface.brightness_visual_weights = { a = 1, b = 0.7, g = 0.7, r = 0.7 }
            end
        end
    )

Commands.new('mtn_grant_permanent_buff', 'Usable only for admins - grants a permanent buff!')
    :require_admin()
    :require_validation('Warning: This command gets logged to discord so please use it wisely!')
    :callback(
        function (player)
            local buff = Public.grant_non_limit_reached_buff()
            local stateful = Public.get_stateful()
            stateful.permanent_buffs[#stateful.permanent_buffs + 1] = buff
            Discord.send_notification(
                {
                    title = "Permanent buff granted",
                    description = player.name .. ' granted the team a permanent buff: ' .. buff.discord,
                    color = "success",
                    fields =
                    {
                        {
                            title = "Server",
                            description = Public.discord_name,
                            inline = "false"
                        }
                    }
                })
            game.print(mapkeeper .. ' ' .. player.name .. ', has granted the permanent buff: ' .. buff.discord .. '!', { color = CommandColor })
            Public.apply_permanent_buffs()
        end
    )


Commands.new('mtn_toggle_orbital_strikes',
    'Usable only for admins - toggles orbital strikes!')
    :require_admin()
    :require_validation()
    :callback(
        function (player)
            local this = Public.get()

            if this.orbital_strikes.enabled then
                Discord.send_notification(
                    {
                        title = "Orbital strikes disabled",
                        description = player.name .. ' disabled the orbital strike module.',
                        color = "success",
                        fields =
                        {
                            {
                                title = "Server",
                                description = Public.discord_name,
                                inline = "false"
                            }
                        }
                    })
                game.print(mapkeeper .. ' ' .. player.name .. ', has disabled the orbital_strikes module!',
                    { color = CommandColor })
                this.orbital_strikes.enabled = false
            else
                Discord.send_notification(
                    {
                        title = "Orbital strikes enabled",
                        description = player.name .. ' enabled the orbital strike module.',
                        color = "success",
                        fields =
                        {
                            {
                                title = "Server",
                                description = Public.discord_name,
                                inline = "false"
                            }
                        }
                    })
                game.print(mapkeeper .. ' ' .. player.name .. ', has enabled the orbital_strikes module!',
                    { color = CommandColor })
                this.orbital_strikes.enabled = true
            end
        end
    )

Commands.new('mtn_get_queue_speed', 'Usable only for admins - gets the queue speed of this map!')
    :require_admin()
    :require_validation()
    :callback(
        function (player)
            player.print(Task.get_queue_speed())
        end
    )

Commands.new('mtn_disable_collapse', 'Usable only for admins - toggles the collapse feature!')
    :require_admin()
    :require_validation()
    :callback(
        function (player)
            if not Collapse.has_collapse_started() then
                Collapse.start_now(true, false)
                Discord.send_notification(
                    {
                        title = "Collapse enabled",
                        description = player.name .. ' has enabled collapse.',
                        color = "success",
                        fields =
                        {
                            {
                                title = "Server",
                                description = Public.discord_name,
                                inline = "false"
                            }
                        }
                    })
                game.print(mapkeeper .. ' ' .. player.name .. ', has enabled collapse!', { color = CommandColor })
            else
                Collapse.start_now(false, true)
                Discord.send_notification(
                    {
                        title = "Collapse disabled",
                        description = player.name .. ' has disabled collapse.',
                        color = "success",
                        fields =
                        {
                            {
                                title = "Server",
                                description = Public.discord_name,
                                inline = "false"
                            }
                        }
                    })
                game.print(mapkeeper .. ' ' .. player.name .. ', has disabled collapse!',
                    { color = CommandColor })
            end
        end
    )

Commands.new('mtn_grant_fake_buff', 'Usable only for admins - used to debug buff selection')
    :require_admin()
    :require_validation()
    :require_offline_mode()
    :callback(
        function ()
            local Core = require('utils.core')
            Public.set('buff_selection', { buffs = {} })
            local b = Public.grant_non_limit_reached_buff(3)
            Public.init_buff_selection(b)

            Core.iter_connected_players(function (p)
                if p and p.valid then
                    Public.buff_main_frame(p)
                end
            end)
        end
    )

--- Rows 1-3 take their name from the difficulty vote module, the extra easier rows carry
--- their own, since they deliberately have no entry in the vote ladder.
local function difficulty_row_name(index, row)
    if row.name then
        return row.name
    end

    local voted = Difficulty.get('difficulties')[index]
    return voted and voted.name or ('row ' .. index)
end

local function difficulty_row_value(index, row)
    if row.value then
        return row.value
    end

    local voted = Difficulty.get('difficulties')[index]
    return voted and voted.value
end

local function pad(text, width, align_right)
    local fill = string.rep(' ', width - #text)
    if align_right then
        return fill .. text
    end
    return text .. fill
end

--- Renders the balance rows as an ascii table. Column widths are measured from the content
--- rather than hardcoded, so adding a row or a balance field cannot break the layout.
local function build_difficulty_table()
    local rows = Public.get_difficulty_balance_rows()
    local fields = Public.get_difficulty_balance_fields()
    local overrides = Public.get_difficulty_overrides()
    local active_index = Difficulty.get('index')

    -- Headed by the raw field names so they can be copied straight into
    -- /mtn_difficulty <field> <value>. Costs width, but keeps the command self-documenting.
    local header = { '', '#', 'name' }
    for _, field in ipairs(fields) do
        header[#header + 1] = field
    end

    local lines = { header }

    for index, row in ipairs(rows) do
        local line =
        {
            index == active_index and '>' or '',
            tostring(index),
            difficulty_row_name(index, row)
        }

        for _, field in ipairs(fields) do
            local value = row[field]
            local marker = ''
            if index == active_index and overrides[field] ~= nil then
                value = overrides[field]
                marker = '*'
            end
            line[#line + 1] = tostring(value) .. marker
        end

        lines[#lines + 1] = line
    end

    local widths = {}
    for _, line in ipairs(lines) do
        for column, cell in ipairs(line) do
            if not widths[column] or #cell > widths[column] then
                widths[column] = #cell
            end
        end
    end

    -- The marker, index and name columns read better left aligned, the numbers right aligned.
    local function render(line)
        local cells = {}
        for column = 1, #widths do
            cells[column] = pad(line[column] or '', widths[column], column > 3)
        end
        return table.concat(cells, ' | ')
    end

    local separator = {}
    for column = 1, #widths do
        separator[column] = string.rep('-', widths[column])
    end

    local out = { render(lines[1]), table.concat(separator, '-+-') }
    for index = 2, #lines do
        out[#out + 1] = render(lines[index])
    end

    return table.concat(out, '\n')
end

local function print_difficulty_state(player)
    -- set_difficulty only runs on its own every 60 ticks, so straight after a row change or an
    -- override the numbers below would still be the previous row's. Re-apply first; it writes the
    -- same values the nth-tick handler would and is safe to call repeatedly.
    Public.set_difficulty()

    -- Read the applied numbers straight off wave defense rather than recomputing them, so
    -- this can never drift from what set_difficulty actually wrote.
    local wd = WD.get_table()

    -- group_size is not a balance row field, so it gets its override marker here rather than in
    -- the table above.
    local group_size = wd.average_unit_group_size .. (Public.get_difficulty_group_size() and '*' or '')

    local applied = table.concat(
        {
            'applied now, ' .. Public.get_difficulty_player_count() .. ' player(s): ',
            'wave_interval=' .. wd.wave_interval .. ' ticks (' .. math.floor(wd.wave_interval / 60) .. 's)',
            ', threat_gain_multiplier=' .. math.round(wd.threat_gain_multiplier, 3),
            ', max_active_biters=' .. math.floor(wd.max_active_biters),
            ', average_unit_group_size=' .. group_size
        }
    )

    -- Leading newline: the first line would otherwise start wherever the console prefix ended.
    player.print(
        '\n' .. build_difficulty_table() .. '\n\n' .. applied .. '\n> = active row, * = overridden value\n',
        { color = CommandColor }
    )
end

Commands.new('mtn_difficulty', 'Usable only for admins - lists the difficulty rows with no argument, otherwise selects a row, overrides a single field, or resets overrides.')
    :require_admin()
    -- 'any' rather than 'string': the framework runs every argument through tonumber before
    -- type checking, so a 'string' parameter rejects "5" and "0.6" outright.
    :add_parameter('row/field/reset', true, 'any')
    :add_parameter('value', true, 'any')
    :callback(
        function (player, target, new_value)
            local rows = Public.get_difficulty_balance_rows()

            if not target then
                print_difficulty_state(player)
                return
            end

            -- May arrive as a number, since the framework pre-converts numeric arguments.
            target = tostring(target)

            if target == 'reset' then
                Public.clear_difficulty_overrides()
                player.print('Difficulty overrides and group size cleared.', { color = CommandColor })
                print_difficulty_state(player)
                return
            end

            -- Selecting a row. Validated against the table rather than leaning on
            -- get_difficulty_balance's fallback, which silently resolves to row 2 (harder).
            local index = tonumber(target)
            if index then
                local row = rows[index]
                if not row then
                    player.print('There is no difficulty row ' .. index .. '. Valid rows are 1-' .. #rows .. '.', { color = Color.warning })
                    return false
                end

                Difficulty.set('index', index)
                local value = difficulty_row_value(index, row)
                if value then
                    Difficulty.set('value', value)
                end
                Public.clear_difficulty_overrides()
                -- Remembered so a map reset restores this row instead of dropping back to 1.
                Public.set_difficulty_prefs(index, value)

                game.print(mapkeeper .. ' difficulty is now ' .. difficulty_row_name(index, row) .. '.', { color = CommandColor })
                print_difficulty_state(player)
                return
            end

            -- Overriding a single field.
            local number = tonumber(new_value)
            if not number then
                player.print('Expected a number for ' .. target .. ', got "' .. tostring(new_value) .. '".', { color = Color.warning })
                return false
            end

            if target == 'group_size' then
                if number < 1 then
                    player.print('group_size must be at least 1.', { color = Color.warning })
                    return false
                end
                local size = math.floor(number)
                Public.set_difficulty_group_size(size)
                player.print('average_unit_group_size set to ' .. size .. '.', { color = CommandColor })
                print_difficulty_state(player)
                return
            end

            local fields = Public.get_difficulty_balance_fields()
            local known = false
            for _, field in ipairs(fields) do
                if field == target then
                    known = true
                    break
                end
            end

            if not known then
                player.print('Unknown field "' .. target .. '". Valid fields: ' .. table.concat(fields, ', ') .. ', group_size.', { color = Color.warning })
                return false
            end

            Public.set_difficulty_override(target, number)

            player.print(target .. ' overridden to ' .. number .. '.', { color = CommandColor })
            print_difficulty_state(player)
        end
    )

return Public
