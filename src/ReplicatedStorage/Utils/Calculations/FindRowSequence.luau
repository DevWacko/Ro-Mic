function FindSequence(board, columns, rows, targetValue, lengthNeeded)
    local directions = {
        {dx = 1, dy = 0}, -- Horizontal →
        {dx = 0, dy = 1}, -- Vertical ↓
        {dx = 1, dy = 1}, -- Diagonal ↘
        {dx = -1, dy = 1} -- Diagonal ↙
    }
    
    for y = 1, columns do
        for x = 1, rows do
            if board[y][x] == targetValue then
                for _, dir in ipairs(directions) do
                    local matchedPositions = {{x = x, y = y}}
                    local success = true
                    
                    for step = 1, lengthNeeded - 1 do
                        local newX = x + dir.dx * step
                        local newY = y + dir.dy * step
                        
                        if newX < 1 or newX > columns or newY < 1 or newY > rows then
                            success = false
                            break
                        end
                        
                        if board[newY][newX] ~= targetValue then
                            success = false
                            break
                        end
                        
                        table.insert(matchedPositions, {x = newX, y = newY})
                    end
                    
                    if success then
                        return true, matchedPositions
                    end
                end
            end
        end
    end
    
    return false, nil
end

return FindSequence