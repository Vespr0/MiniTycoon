local Rarities = {
    Common = {
        DisplayName = "Common";
        Color = Color3.fromRGB(255, 255, 255);
        StrokeColor = Color3.fromRGB(22, 22, 22);
    };
    Rare = {
        DisplayName = "Rare";
        Color = Color3.fromRGB(139, 189, 255);
        StrokeColor = Color3.fromRGB(37, 46, 66);
    };
    Collectors = {
        DisplayName = "Collector's";
        Color = Color3.fromRGB(255, 50, 85);
        StrokeColor = Color3.fromRGB(50, 0, 0);
    };
    Unusual = {
        DisplayName = "Unusual";
        Color = Color3.fromRGB(201, 64, 255);
        StrokeColor = Color3.fromRGB(47, 36, 65);
    };
    Admin = {
        DisplayName = "Admin";
        Color = Color3.fromRGB(10, 50, 255);
        StrokeColor = Color3.fromRGB(0, 0, 0);
    };
}

return {
    Rarities = Rarities;
}