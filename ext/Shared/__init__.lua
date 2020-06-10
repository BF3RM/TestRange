BodyParts = {"Body", "Head", "Right Arm", "Left Arm", "Right Leg", "Left Leg"}

-- Round numbers up to a given amount of decimal places
function round(num, numDecimalPlaces)
    return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

-- Convert a string into boolean. Return nil if the string is not a valid boolean.
function toboolean(string)
    if (string and (string:lower() == "true" or string == "1")) then
        return true
    end
    if (string and (string:lower() == "false" or string == "0")) then
        return false
    end
    return nil
end