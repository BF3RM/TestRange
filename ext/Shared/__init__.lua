BodyParts = {"Body", "Head", "Right Arm", "Left Arm", "Right Leg", "Left Leg"}

function round(num, numDecimalPlaces)
    return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end