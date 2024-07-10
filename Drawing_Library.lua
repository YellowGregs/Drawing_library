local coreGui = game:GetService("CoreGui")

local camera = workspace.CurrentCamera
local drawingUI = Instance.new("ScreenGui")
drawingUI.Name = "Drawing"
drawingUI.IgnoreGuiInset = true
drawingUI.DisplayOrder = 0x7fffffff
drawingUI.Parent = coreGui

local drawingIndex = 0
local drawingFontsEnum = {
    [0] = Font.fromEnum(Enum.Font.Roboto),
    [1] = Font.fromEnum(Enum.Font.Legacy),
    [2] = Font.fromEnum(Enum.Font.SourceSans),
    [3] = Font.fromEnum(Enum.Font.RobotoMono)
}

local function getFontFromIndex(fontIndex)
    return drawingFontsEnum[fontIndex]
end

local function convertTransparency(transparency)
    return math.clamp(1 - transparency, 0, 1)
end

local baseDrawingObj = setmetatable({
    Visible = true,
    ZIndex = 0,
    Transparency = 1,
    Color = Color3.new(),
    Remove = function(self)
        setmetatable(self, nil)
    end,
    Destroy = function(self)
        setmetatable(self, nil)
    end
}, {
    __add = function(t1, t2)
        local result = {}
        for index, value in pairs(t1) do
            result[index] = value
        end
        for index, value in pairs(t2) do
            result[index] = value
        end
        return result
    end
})

local DrawingLib = {}
DrawingLib.Fonts = {
    ["UI"] = 0,
    ["System"] = 1,
    ["Plex"] = 2,
    ["Monospace"] = 3
}

function DrawingLib.new(drawingType)
    drawingIndex += 1
    if drawingType == "Line" then
        return DrawingLib.createLine()
    elseif drawingType == "Text" then
        return DrawingLib.createText()
    elseif drawingType == "Circle" then
        return DrawingLib.createCircle()
    elseif drawingType == "Square" then
        return DrawingLib.createSquare()
    elseif drawingType == "Image" then
        return DrawingLib.createImage()
    elseif drawingType == "Quad" then
        return DrawingLib.createQuad()
    elseif drawingType == "Triangle" then
        return DrawingLib.createTriangle()
    end
end

function DrawingLib.createLine()
    local lineObj = ({
        From = Vector2.zero,
        To = Vector2.zero,
        Thickness = 1
    } + baseDrawingObj)

    local lineFrame = Instance.new("Frame")
    lineFrame.Name = drawingIndex
    lineFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    lineFrame.BorderSizePixel = 0

    lineFrame.Parent = drawingUI
    return setmetatable({}, {
        __newindex = function(_, index, value)
            if lineObj[index] == nil then return end

            if index == "From" or index == "To" then
                local direction = (index == "From" and lineObj.To or value) - (index == "From" and value or lineObj.From)
                local center = (lineObj.To + lineObj.From) / 2
                local distance = direction.Magnitude
                local theta = math.deg(math.atan2(direction.Y, direction.X))

                lineFrame.Position = UDim2.fromOffset(center.X, center.Y)
                lineFrame.Rotation = theta
                lineFrame.Size = UDim2.fromOffset(distance, lineObj.Thickness)
            elseif index == "Thickness" then
                lineFrame.Size = UDim2.fromOffset((lineObj.To - lineObj.From).Magnitude, value)
            elseif index == "Visible" then
                lineFrame.Visible = value
            elseif index == "ZIndex" then
                lineFrame.ZIndex = value
            elseif index == "Transparency" then
                lineFrame.BackgroundTransparency = convertTransparency(value)
            elseif index == "Color" then
                lineFrame.BackgroundColor3 = value
            end
            lineObj[index] = value
        end,
        __index = function(self, index)
            if index == "Remove" or index == "Destroy" then
                return function()
                    lineFrame:Destroy()
                    lineObj:Remove()
                end
            end
            return lineObj[index]
        end,
        __tostring = function() return "Drawing" end
    })
end

function DrawingLib.createText()
    local textObj = ({
        Text = "",
        Font = DrawingLib.Fonts.UI,
        Size = 0,
        Position = Vector2.zero,
        Center = false,
        Outline = false,
        OutlineColor = Color3.new()
    } + baseDrawingObj)

    local textLabel, uiStroke = Instance.new("TextLabel"), Instance.new("UIStroke")
    textLabel.Name = drawingIndex
    textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    textLabel.BorderSizePixel = 0
    textLabel.BackgroundTransparency = 1

    local function updateTextPosition()
        local textBounds = textLabel.TextBounds
        local offset = textBounds / 2
        textLabel.Size = UDim2.fromOffset(textBounds.X, textBounds.Y)
        textLabel.Position = UDim2.fromOffset(textObj.Position.X + (not textObj.Center and offset.X or 0), textObj.Position.Y + offset.Y)
    end

    textLabel:GetPropertyChangedSignal("TextBounds"):Connect(updateTextPosition)

    uiStroke.Thickness = 1
    uiStroke.Enabled = textObj.Outline
    uiStroke.Color = textObj.Color

    textLabel.Parent, uiStroke.Parent = drawingUI, textLabel

    return setmetatable({}, {
        __newindex = function(_, index, value)
            if textObj[index] == nil then return end

            if index == "Text" then
                textLabel.Text = value
            elseif index == "Font" then
                textLabel.FontFace = getFontFromIndex(math.clamp(value, 0, 3))
            elseif index == "Size" then
                textLabel.TextSize = value
            elseif index == "Position" then
                updateTextPosition()
            elseif index == "Center" then
                textLabel.Position = UDim2.fromOffset((value and camera.ViewportSize / 2 or textObj.Position).X, textObj.Position.Y)
            elseif index == "Outline" then
                uiStroke.Enabled = value
            elseif index == "OutlineColor" then
                uiStroke.Color = value
            elseif index == "Visible" then
                textLabel.Visible = value
            elseif index == "ZIndex" then
                textLabel.ZIndex = value
            elseif index == "Transparency" then
                local transparency = convertTransparency(value)
                textLabel.TextTransparency = transparency
                uiStroke.Transparency = transparency
            elseif index == "Color" then
                textLabel.TextColor3 = value
            end
            textObj[index] = value
        end,
        __index = function(self, index)
            if index == "Remove" or index == "Destroy" then
                return function()
                    textLabel:Destroy()
                    textObj:Remove()
                end
            elseif index == "TextBounds" then
                return textLabel.TextBounds
            end
            return textObj[index]
        end,
        __tostring = function() return "Drawing" end
    })
end

function DrawingLib.createCircle()
    local circleObj = ({
        Radius = 150,
        Position = Vector2.zero,
        Thickness = 0.7,
        Filled = false
    } + baseDrawingObj)

    local circleFrame, uiCorner, uiStroke = Instance.new("Frame"), Instance.new("UICorner"), Instance.new("UIStroke")
    circleFrame.Name = drawingIndex
    circleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    circleFrame.BorderSizePixel = 0

    uiCorner.CornerRadius = UDim.new(1, 0)
    circleFrame.Size = UDim2.fromOffset(circleObj.Radius, circleObj.Radius)
    uiStroke.Thickness = circleObj.Thickness
    uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    circleFrame.Parent, uiCorner.Parent, uiStroke.Parent = drawingUI, circleFrame, circleFrame

    return setmetatable({}, {
        __newindex = function(_, index, value)
            if circleObj[index] == nil then return end

            if index == "Radius" then
                local radius = value * 2
                circleFrame.Size = UDim2.fromOffset(radius, radius)
            elseif index == "Position" then
                circleFrame.Position = UDim2.fromOffset(value.X, value.Y)
            elseif index == "Thickness" then
                uiStroke.Thickness = math.clamp(value, 0.6, 0x7fffffff)
            elseif index == "Filled" then
                circleFrame.BackgroundTransparency = value and convertTransparency(circleObj.Transparency) or 1
                uiStroke.Enabled = not value
            elseif index == "Visible" then
                circleFrame.Visible = value
            elseif index == "ZIndex" then
                circleFrame.ZIndex = value
            elseif index == "Transparency" then
                local transparency = convertTransparency(value)
                circleFrame.BackgroundTransparency = circleObj.Filled and transparency or 1
                uiStroke.Transparency = transparency
            elseif index == "Color" then
                circleFrame.BackgroundColor3 = value
                uiStroke.Color = value
            end
            circleObj[index] = value
        end,
        __index = function(self, index)
            if index == "Remove" or index == "Destroy" then
                return function()
                    circleFrame:Destroy()
                    circleObj:Remove()
                end
            end
            return circleObj[index]
        end,
        __tostring = function() return "Drawing" end
    })
end

function DrawingLib.createSquare()
    local squareObj = ({
        Size = Vector2.zero,
        Position = Vector2.zero,
        Thickness = 0.7,
        Filled = false
    } + baseDrawingObj)

    local squareFrame, uiStroke = Instance.new("Frame"), Instance.new("UIStroke")
    squareFrame.Name = drawingIndex
    squareFrame.BorderSizePixel = 0

    squareFrame.Parent, uiStroke.Parent = drawingUI, squareFrame

    return setmetatable({}, {
        __newindex = function(_, index, value)
            if squareObj[index] == nil then return end

            if index == "Size" then
                squareFrame.Size = UDim2.fromOffset(value.X, value.Y)
            elseif index == "Position" then
                squareFrame.Position = UDim2.fromOffset(value.X, value.Y)
            elseif index == "Thickness" then
                uiStroke.Thickness = math.clamp(value, 0.6, 0x7fffffff)
            elseif index == "Filled" then
                squareFrame.BackgroundTransparency = value and convertTransparency(squareObj.Transparency) or 1
                uiStroke.Enabled = not value
            elseif index == "Visible" then
                squareFrame.Visible = value
            elseif index == "ZIndex" then
                squareFrame.ZIndex = value
            elseif index == "Transparency" then
                local transparency = convertTransparency(value)
                squareFrame.BackgroundTransparency = squareObj.Filled and transparency or 1
                uiStroke.Transparency = transparency
            elseif index == "Color" then
                squareFrame.BackgroundColor3 = value
                uiStroke.Color = value
            end
            squareObj[index] = value
        end,
        __index = function(self, index)
            if index == "Remove" or index == "Destroy" then
                return function()
                    squareFrame:Destroy()
                    squareObj:Remove()
                end
            end
            return squareObj[index]
        end,
        __tostring = function() return "Drawing" end
    })
end

function DrawingLib.createImage()
    local imageObj = ({
        Data = "",
        DataURL = "rbxassetid://0",
        Size = Vector2.zero,
        Position = Vector2.zero
    } + baseDrawingObj)

    local imageFrame = Instance.new("ImageLabel")
    imageFrame.Name = drawingIndex
    imageFrame.BorderSizePixel = 0
    imageFrame.ScaleType = Enum.ScaleType.Stretch
    imageFrame.BackgroundTransparency = 1

    imageFrame.Parent = drawingUI

    return setmetatable({}, {
        __newindex = function(_, index, value)
            if imageObj[index] == nil then return end

            if index == "Data" then
            elseif index == "DataURL" then
                imageFrame.Image = value
            elseif index == "Size" then
                imageFrame.Size = UDim2.fromOffset(value.X, value.Y)
            elseif index == "Position" then
                imageFrame.Position = UDim2.fromOffset(value.X, value.Y)
            elseif index == "Visible" then
                imageFrame.Visible = value
            elseif index == "ZIndex" then
                imageFrame.ZIndex = value
            elseif index == "Transparency" then
                imageFrame.ImageTransparency = convertTransparency(value)
            elseif index == "Color" then
                imageFrame.ImageColor3 = value
            end
            imageObj[index] = value
        end,
        __index = function(self, index)
            if index == "Remove" or index == "Destroy" then
                return function()
                    imageFrame:Destroy()
                    imageObj:Remove()
                end
            elseif index == "Data" then
                return nil
            end
            return imageObj[index]
        end,
        __tostring = function() return "Drawing" end
    })
end

function DrawingLib.createQuad()
    local quadObj = ({
        PointA = Vector2.zero,
        PointB = Vector2.zero,
        PointC = Vector2.zero,
        PointD = Vector3.zero,
        Thickness = 1,
        Filled = false
    } + baseDrawingObj)

    local _linePoints = {
        A = DrawingLib.createLine(),
        B = DrawingLib.createLine(),
        C = DrawingLib.createLine(),
        D = DrawingLib.createLine()
    }

    return setmetatable({}, {
        __newindex = function(_, index, value)
            if quadObj[index] == nil then return end

            if index == "PointA" then
                _linePoints.A.From = value
                _linePoints.B.To = value
            elseif index == "PointB" then
                _linePoints.B.From = value
                _linePoints.C.To = value
            elseif index == "PointC" then
                _linePoints.C.From = value
                _linePoints.D.To = value
            elseif index == "PointD" then
                _linePoints.D.From = value
                _linePoints.A.To = value
            elseif index == "Thickness" or index == "Visible" or index == "Color" or index == "ZIndex" then
                for _, linePoint in pairs(_linePoints) do
                    linePoint[index] = value
                end
            elseif index == "Filled" then
                for _, linePoint in pairs(_linePoints) do
                    linePoint.Transparency = value and 1 or quadObj.Transparency
                end
                -- im lazy 
            end
            quadObj[index] = value
        end,
        __index = function(self, index)
            if index == "Remove" or index == "Destroy" then
                return function()
                    for _, linePoint in pairs(_linePoints) do
                        linePoint:Remove()
                    end
                    quadObj:Remove()
                end
            end
            return quadObj[index]
        end,
        __tostring = function() return "Drawing" end
    })
end

function DrawingLib.createTriangle()
    local triangleObj = ({
        PointA = Vector2.zero,
        PointB = Vector2.zero,
        PointC = Vector2.zero,
        Thickness = 1,
        Filled = false
    } + baseDrawingObj)

    local _linePoints = {
        A = DrawingLib.createLine(),
        B = DrawingLib.createLine(),
        C = DrawingLib.createLine()
    }

    return setmetatable({}, {
        __newindex = function(_, index, value)
            if triangleObj[index] == nil then return end

            if index == "PointA" then
                _linePoints.A.From = value
                _linePoints.B.To = value
            elseif index == "PointB" then
                _linePoints.B.From = value
                _linePoints.C.To = value
            elseif index == "PointC" then
                _linePoints.C.From = value
                _linePoints.A.To = value
            elseif index == "Thickness" or index == "Visible" or index == "Color" or index == "ZIndex" then
                for _, linePoint in pairs(_linePoints) do
                    linePoint[index] = value
                end
            elseif index == "Filled" then
                for _, linePoint in pairs(_linePoints) do
                    linePoint.Transparency = value and 1 or triangleObj.Transparency
                end
                --could add more but im lazy
            end
            triangleObj[index] = value
        end,
        __index = function(self, index)
            if index == "Remove" or index == "Destroy" then
                return function()
                    for _, linePoint in pairs(_linePoints) do
                        linePoint:Remove()
                    end
                    triangleObj:Remove()
                end
            end
            return triangleObj[index]
        end,
        __tostring = function() return "Drawing" end
    })
end

return DrawingLib
