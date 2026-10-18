.pragma library

const CATEGORIES = {
    length: {
        name: "Length",
        icon: "straighten",
        defaultFrom: "m",
        defaultTo: "km",
        units: [
            { id: "m", name: "m", desc: "Meter", factor: 1 },
            { id: "km", name: "km", desc: "Kilometer", factor: 1000 },
            { id: "cm", name: "cm", desc: "Centimeter", factor: 0.01 },
            { id: "mm", name: "mm", desc: "Millimeter", factor: 0.001 },
            { id: "mi", name: "mi", desc: "Mile", factor: 1609.344 },
            { id: "yd", name: "yd", desc: "Yard", factor: 0.9144 },
            { id: "ft", name: "ft", desc: "Foot", factor: 0.3048 },
            { id: "in", name: "in", desc: "Inch", factor: 0.0254 },
            { id: "nmi", name: "NM", desc: "Nautical Mile", factor: 1852 }
        ]
    },
    mass: {
        name: "Weight",
        icon: "fitness_center",
        defaultFrom: "kg",
        defaultTo: "lb",
        units: [
            { id: "kg", name: "kg", desc: "Kilogram", factor: 1 },
            { id: "g", name: "g", desc: "Gram", factor: 0.001 },
            { id: "mg", name: "mg", desc: "Milligram", factor: 1e-6 },
            { id: "t", name: "t", desc: "Metric Ton", factor: 1000 },
            { id: "lb", name: "lb", desc: "Pound", factor: 0.45359237 },
            { id: "oz", name: "oz", desc: "Ounce", factor: 0.028349523125 }
        ]
    },
    temperature: {
        name: "Temperature",
        icon: "thermostat",
        defaultFrom: "C",
        defaultTo: "F",
        units: [
            { id: "C", name: "°C", desc: "Celsius" },
            { id: "F", name: "°F", desc: "Fahrenheit" },
            { id: "K", name: "K", desc: "Kelvin" }
        ]
    },
    area: {
        name: "Area",
        icon: "crop_square",
        defaultFrom: "m2",
        defaultTo: "ft2",
        units: [
            { id: "m2", name: "m²", desc: "Square Meter", factor: 1 },
            { id: "km2", name: "km²", desc: "Square Kilometer", factor: 1e6 },
            { id: "cm2", name: "cm²", desc: "Square Centimeter", factor: 1e-4 },
            { id: "ha", name: "ha", desc: "Hectare", factor: 10000 },
            { id: "ac", name: "ac", desc: "Acre", factor: 4046.8564224 },
            { id: "ft2", name: "ft²", desc: "Square Foot", factor: 0.09290304 },
            { id: "mi2", name: "mi²", desc: "Square Mile", factor: 2589988.110336 }
        ]
    },
    volume: {
        name: "Volume",
        icon: "local_drink",
        defaultFrom: "L",
        defaultTo: "gal",
        units: [
            { id: "L", name: "L", desc: "Liter", factor: 1 },
            { id: "mL", name: "mL", desc: "Milliliter", factor: 0.001 },
            { id: "m3", name: "m³", desc: "Cubic Meter", factor: 1000 },
            { id: "gal", name: "gal", desc: "US Gallon", factor: 3.785411784 },
            { id: "qt", name: "qt", desc: "US Quart", factor: 0.946352946 },
            { id: "pt", name: "pt", desc: "US Pint", factor: 0.473176473 },
            { id: "cup", name: "cup", desc: "US Cup", factor: 0.2365882365 },
            { id: "floz", name: "fl oz", desc: "Fluid Ounce", factor: 0.0295735295625 }
        ]
    },
    speed: {
        name: "Speed",
        icon: "speed",
        defaultFrom: "kmh",
        defaultTo: "mph",
        units: [
            { id: "kmh", name: "km/h", desc: "Kilometer/hour", factor: 1 / 3.6 },
            { id: "ms", name: "m/s", desc: "Meter/second", factor: 1 },
            { id: "mph", name: "mph", desc: "Mile/hour", factor: 0.44704 },
            { id: "kn", name: "kn", desc: "Knot", factor: 0.514444444444 },
            { id: "fts", name: "ft/s", desc: "Foot/second", factor: 0.3048 }
        ]
    },
    time: {
        name: "Time",
        icon: "schedule",
        defaultFrom: "h",
        defaultTo: "min",
        units: [
            { id: "ms", name: "ms", desc: "Millisecond", factor: 0.001 },
            { id: "s", name: "s", desc: "Second", factor: 1 },
            { id: "min", name: "min", desc: "Minute", factor: 60 },
            { id: "h", name: "h", desc: "Hour", factor: 3600 },
            { id: "d", name: "d", desc: "Day", factor: 86400 },
            { id: "wk", name: "wk", desc: "Week", factor: 604800 },
            { id: "yr", name: "yr", desc: "Year", factor: 31536000 }
        ]
    },
    data: {
        name: "Storage",
        icon: "hard_drive",
        defaultFrom: "GB",
        defaultTo: "MB",
        units: [
            { id: "B", name: "B", desc: "Byte", factor: 1 },
            { id: "KB", name: "KB", desc: "Kilobyte", factor: 1024 },
            { id: "MB", name: "MB", desc: "Megabyte", factor: 1048576 },
            { id: "GB", name: "GB", desc: "Gigabyte", factor: 1073741824 },
            { id: "TB", name: "TB", desc: "Terabyte", factor: 1099511627776 }
        ]
    },
    pressure: {
        name: "Pressure",
        icon: "compress",
        defaultFrom: "bar",
        defaultTo: "psi",
        units: [
            { id: "Pa", name: "Pa", desc: "Pascal", factor: 1 },
            { id: "kPa", name: "kPa", desc: "Kilopascal", factor: 1000 },
            { id: "hPa", name: "hPa", desc: "Hectopascal", factor: 100 },
            { id: "bar", name: "bar", desc: "Bar", factor: 100000 },
            { id: "psi", name: "psi", desc: "Pound/sq inch", factor: 6894.757 },
            { id: "atm", name: "atm", desc: "Atmosphere", factor: 101325 },
            { id: "mmHg", name: "mmHg", desc: "Millimeter of mercury", factor: 133.322 }
        ]
    },
    power: {
        name: "Power",
        icon: "bolt",
        defaultFrom: "kW",
        defaultTo: "hp",
        units: [
            { id: "W", name: "W", desc: "Watt", factor: 1 },
            { id: "kW", name: "kW", desc: "Kilowatt", factor: 1000 },
            { id: "hp", name: "hp", desc: "Horsepower", factor: 745.699872 },
            { id: "ps", name: "PS", desc: "Metric horsepower", factor: 735.49875 },
            { id: "MW", name: "MW", desc: "Megawatt", factor: 1e6 },
            { id: "btuh", name: "BTU/h", desc: "BTU per hour", factor: 0.29307107 }
        ]
    },
    energy: {
        name: "Energy",
        icon: "local_fire_department",
        defaultFrom: "kJ",
        defaultTo: "kcal",
        units: [
            { id: "J", name: "J", desc: "Joule", factor: 1 },
            { id: "kJ", name: "kJ", desc: "Kilojoule", factor: 1000 },
            { id: "cal", name: "cal", desc: "Calorie", factor: 4.184 },
            { id: "kcal", name: "kcal", desc: "Kilocalorie", factor: 4184 },
            { id: "Wh", name: "Wh", desc: "Watt-hour", factor: 3600 },
            { id: "kWh", name: "kWh", desc: "Kilowatt-hour", factor: 3.6e6 },
            { id: "eV", name: "eV", desc: "Electronvolt", factor: 1.602176634e-19 },
            { id: "btu", name: "BTU", desc: "British Thermal Unit", factor: 1055.056 }
        ]
    }
};

const CATEGORY_KEYS = [
    "length",
    "mass",
    "temperature",
    "area",
    "volume",
    "speed",
    "time",
    "data",
    "pressure",
    "power",
    "energy"
];

function getCategory(key) {
    return CATEGORIES[key] || CATEGORIES.length;
}

function getCategoryList() {
    return CATEGORY_KEYS.map(k => ({
        key: k,
        name: CATEGORIES[k].name,
        icon: CATEGORIES[k].icon
    }));
}

function getUnitsForCategory(key) {
    const cat = CATEGORIES[key];
    return cat ? cat.units : [];
}

function getUnitName(categoryKey, unitId) {
    const cat = CATEGORIES[categoryKey];
    if (!cat) return unitId;
    const unit = cat.units.find(u => u.id === unitId);
    return unit ? unit.name : unitId;
}

function convert(categoryKey, valueStr, fromId, toId) {
    if (!valueStr || valueStr.trim() === "" || valueStr === "-") {
        return "0";
    }

    const val = parseFloat(valueStr);
    if (isNaN(val)) return "0";
    if (fromId === toId) return valueStr;

    const cat = CATEGORIES[categoryKey];
    if (!cat) return "0";

    if (categoryKey === "temperature") {
        let inCelsius = val;
        if (fromId === "F") inCelsius = (val - 32) * 5 / 9;
        else if (fromId === "K") inCelsius = val - 273.15;

        let res = inCelsius;
        if (toId === "F") res = inCelsius * 9 / 5 + 32;
        else if (toId === "K") res = inCelsius + 273.15;
        return formatResult(res);
    }

    const fromUnit = cat.units.find(u => u.id === fromId);
    const toUnit = cat.units.find(u => u.id === toId);
    if (!fromUnit || !toUnit) return "0";

    const baseVal = val * fromUnit.factor;
    const res = baseVal / toUnit.factor;
    return formatResult(res);
}

function formatResult(num) {
    if (num === 0) return "0";
    if (Math.abs(num) >= 1e12 || (Math.abs(num) < 1e-6 && num !== 0)) {
        return num.toExponential(4).replace("+", "");
    }
    return parseFloat(num.toPrecision(8)).toString();
}
