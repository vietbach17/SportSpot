using SportSpot.Data.Context;
using SportSpot.Data.Entities;

namespace SportSpot.Data.SeedData;

public static class DbInitializer
{
    // Hàm hỗ trợ seed sân mẫu cho môi trường dev (giữ nguyên 100% của Member 1)
    public static void SeedDevVenues(SportSpotDbContext context)
    {
        if (context.Venues.Any())
        {
            SeedMissingSubVenues(context);
            return;
        }

        var venue1 = new Venue
        {
            SportId = 1,
            Name = "CLB Cầu Lông Cầu Giấy",
            Address = "Số 35 Trần Quý Kiên, Dịch Vọng",
            District = "Cầu Giấy",
            Latitude = 21.0368000m,
            Longitude = 105.7905000m,
            Description = "Cụm 6 sân thảm tiêu chuẩn thi đấu.",
            Hotline = "0987654321",
            BasePrice = 90000,
            PeakPrice = 120000,
            Rating = 4.9m,
            Amenities = "Bãi đỗ ô tô, Căn tin, Phòng tắm, Cho thuê vợt",
            ImageUrl = "https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800",
            IsActive = true
        };

        var venue2 = new Venue
        {
            SportId = 2,
            Name = "Sân Bóng Đá Mini PVV",
            Address = "Số 72 Trần Thái Tông, Dịch Vọng Hậu",
            District = "Cầu Giấy",
            Latitude = 21.0305000m,
            Longitude = 105.7865000m,
            Description = "Cụm sân cỏ nhân tạo 7 người chất lượng cao.",
            Hotline = "0912345678",
            BasePrice = 350000,
            PeakPrice = 600000,
            Rating = 4.7m,
            Amenities = "Đèn chiếu sáng ban đêm, Trọng tài, Căn tin, Giữ xe miễn phí",
            ImageUrl = "https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800",
            IsActive = true
        };

        context.Venues.AddRange(venue1, venue2);
        context.SaveChanges();
        SeedMissingSubVenues(context);
    }

    private static void SeedMissingSubVenues(SportSpotDbContext context)
    {
        foreach (var venue in context.Venues.Where(v => !v.SubVenues.Any()).ToList())
            context.SubVenues.Add(new SubVenue { VenueId = venue.Id, Name = "Sân 1", IsActive = true });
        context.SaveChanges();
    }
}
