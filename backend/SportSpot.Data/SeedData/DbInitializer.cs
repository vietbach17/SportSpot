using SportSpot.Data.Context;
using SportSpot.Data.Entities;

namespace SportSpot.Data.SeedData;

public static class DbInitializer
{
    public static void SeedDevVenues(SportSpotDbContext context)
    {
        // 1. Seed Default Dev User nếu chưa có
        if (!context.Users.Any())
        {
            context.Users.Add(new User
            {
                PhoneNumber = "0988888888",
                FullName = "Nguyễn Văn A (Host)",
                Email = "devuser@sportspot.vn",
                Role = "Customer",
                WalletBalance = 500000,
                IsFindMatchEnabled = true,
                FavoriteSports = "Cầu lông, Bóng đá mini",
                CreatedAt = DateTime.UtcNow
            });
            context.SaveChanges();
        }

        // 2. Seed Venues
        if (!context.Venues.Any())
        {
            var venue1 = new Venue
            {
                SportId = 1,
                Name = "CLB Cầu Lông Cầu Giấy",
                Address = "Số 35 Trần Quý Kiên, Dịch Vọng",
                District = "Cầu Giấy",
                Latitude = 21.0368000m,
                Longitude = 105.7905000m,
                Description = "Cụm sân thảm tiêu chuẩn thi đấu, trần cao thoáng mát.",
                Hotline = "0987654321",
                BasePrice = 90000,
                PeakPrice = 120000,
                Rating = 4.9m,
                Amenities = "Bãi đỗ ô tô, Căn tin, Phòng tắm, Cho thuê vợt, Wifi",
                ImageUrl = "https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800",
                IsActive = true
            };

            var venue2 = new Venue
            {
                SportId = 3, // Bóng đá mini
                Name = "Sân Bóng Đá Mini PVV",
                Address = "Số 72 Trần Thái Tông, Dịch Vọng Hậu",
                District = "Cầu Giấy",
                Latitude = 21.0305000m,
                Longitude = 105.7865000m,
                Description = "Cụm sân cỏ nhân tạo 7 người chất lượng cao chống trơn trượt.",
                Hotline = "0912345678",
                BasePrice = 350000,
                PeakPrice = 600000,
                Rating = 4.7m,
                Amenities = "Đèn chiếu sáng ban đêm, Trọng tài, Căn tin, Giữ xe miễn phí",
                ImageUrl = "https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800",
                IsActive = true
            };

            var venue3 = new Venue
            {
                SportId = 2, // Pickleball
                Name = "Pickleball Club D-Sport",
                Address = "Số 10 Chu Văn An, Bình Thạnh",
                District = "Bình Thạnh",
                Latitude = 10.8122000m,
                Longitude = 106.6975000m,
                Description = "Sân Pickleball mặt sân cao cấp chuẩn quốc tế USAPA.",
                Hotline = "0903112233",
                BasePrice = 110000,
                PeakPrice = 150000,
                Rating = 4.8m,
                Amenities = "Phòng thay đồ, Huấn luyện viên, Cho thuê bóng & vợt",
                ImageUrl = "https://images.unsplash.com/photo-1599586120429-48281b6f0ece?w=800",
                IsActive = true
            };

            context.Venues.AddRange(venue1, venue2, venue3);
            context.SaveChanges();
        }

        SeedSubVenuesAndServices(context);
    }

    private static void SeedSubVenuesAndServices(SportSpotDbContext context)
    {
        var venues = context.Venues.ToList();
        foreach (var venue in venues)
        {
            // Seed SubVenues nếu chưa có
            if (!context.SubVenues.Any(sv => sv.VenueId == venue.Id))
            {
                if (venue.SportId == 1) // Cầu lông
                {
                    context.SubVenues.AddRange(
                        new SubVenue { VenueId = venue.Id, Name = "Sân Thảm 1", IsActive = true },
                        new SubVenue { VenueId = venue.Id, Name = "Sân Thảm 2", IsActive = true },
                        new SubVenue { VenueId = venue.Id, Name = "Sân Thảm 3", IsActive = true }
                    );
                }
                else if (venue.SportId == 3) // Bóng đá
                {
                    context.SubVenues.AddRange(
                        new SubVenue { VenueId = venue.Id, Name = "Sân Cỏ 7A", IsActive = true },
                        new SubVenue { VenueId = venue.Id, Name = "Sân Cỏ 7B", IsActive = true }
                    );
                }
                else // Pickleball hoặc khác
                {
                    context.SubVenues.AddRange(
                        new SubVenue { VenueId = venue.Id, Name = "Sân 1", IsActive = true },
                        new SubVenue { VenueId = venue.Id, Name = "Sân 2", IsActive = true }
                    );
                }
            }

            // Seed Services nếu chưa có
            if (!context.Services.Any(s => s.VenueId == venue.Id))
            {
                context.Services.AddRange(
                    new Service { VenueId = venue.Id, Name = "Nước điện giải Revive", Type = "Sale", Price = 15000, StockQuantity = 100 },
                    new Service { VenueId = venue.Id, Name = "Nước suối Aquafina 500ml", Type = "Sale", Price = 10000, StockQuantity = 200 },
                    new Service { VenueId = venue.Id, Name = venue.SportId == 3 ? "Thuê áo pitch phân đội (bộ)" : "Thuê vợt thi đấu cao cấp", Type = "Rental", Price = venue.SportId == 3 ? 20000 : 30000, StockQuantity = 20 },
                    new Service { VenueId = venue.Id, Name = venue.SportId == 3 ? "Thuê bóng thi đấu số 5" : "Ống cầu lông / Bóng tập", Type = "Rental", Price = 25000, StockQuantity = 30 }
                );
            }
        }
        context.SaveChanges();
    }
}
