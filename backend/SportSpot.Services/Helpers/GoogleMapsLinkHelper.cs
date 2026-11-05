using System.Globalization;
using System.Text.RegularExpressions;

namespace SportSpot.Services.Helpers;

public static class GoogleMapsLinkHelper
{
    public static bool IsMapsUrl(Uri uri) => uri.Scheme == "https" && uri.IsDefaultPort && string.IsNullOrEmpty(uri.UserInfo)
        && (uri.Host == "maps.app.goo.gl"
            || (uri.Host == "goo.gl" && uri.AbsolutePath.StartsWith("/maps", StringComparison.OrdinalIgnoreCase))
            || uri.Host == "maps.google.com"
            || ((uri.Host is "google.com" or "www.google.com" or "google.com.vn" or "www.google.com.vn")
                && uri.AbsolutePath.StartsWith("/maps", StringComparison.OrdinalIgnoreCase)));

    public static (decimal Latitude, decimal Longitude)? Parse(string url)
    {
        var text = Uri.UnescapeDataString(url);
        // A place's pin is more accurate than the map viewport's @ coordinates.
        var match = Regex.Match(text, @"!3d(-?\d+(?:\.\d+)?)!4d(-?\d+(?:\.\d+)?)");
        if (!match.Success) match = Regex.Match(text, @"[?&](?:q|query|ll|destination|center)=(-?\d+(?:\.\d+)?)[,\s+]\s*(-?\d+(?:\.\d+)?)", RegexOptions.IgnoreCase);
        if (!match.Success) match = Regex.Match(text, @"@(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)");
        if (match.Success
            && decimal.TryParse(match.Groups[1].Value, NumberStyles.Float, CultureInfo.InvariantCulture, out var lat)
            && decimal.TryParse(match.Groups[2].Value, NumberStyles.Float, CultureInfo.InvariantCulture, out var lng)
            && lat is >= -90 and <= 90 && lng is >= -180 and <= 180)
            return (lat, lng);
        return null;
    }
}
