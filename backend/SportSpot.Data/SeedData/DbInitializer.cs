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

        // 2. Seed 5 Cụm sân thể thao có thật tại TP.HCM (GPS thật phục vụ test khoảng cách)
        var venuesToAdd = new List<Venue>();

        if (!context.Venues.Any(v => v.Name.Contains("Kỳ Hòa")))
        {
            venuesToAdd.Add(new Venue
            {
                SportId = 1, // Cầu lông
                Name = "CLB Cầu Lông Kỳ Hòa",
                Address = "Số 238 đường 3/2, Phường 12",
                District = "Quận 10",
                Latitude = 10.7725000m,
                Longitude = 106.6710000m,
                Description = "Cụm 8 sân thảm tiêu chuẩn Yonex, trần cao 11m thoáng mát, đèn led chống chói chuyên dụng.",
                Hotline = "0903123456",
                BasePrice = 100000,
                PeakPrice = 140000,
                Rating = 4.9m,
                Amenities = "Bãi đỗ ô tô, Căn tin, Phòng tắm nóng lạnh, Cho thuê vợt cao cấp, Wifi tốc độ cao",
                ImageUrl = "https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800",
                IsActive = true
            });
        }

        if (!context.Venues.Any(v => v.Name.Contains("Chảo Lửa")))
        {
            venuesToAdd.Add(new Venue
            {
                SportId = 3, // Bóng đá mini
                Name = "Sân Bóng Đá Mini Chảo Lửa",
                Address = "Số 30 Phan Thúc Duyện, Phường 4",
                District = "Tân Bình",
                Latitude = 10.8033000m,
                Longitude = 106.6575000m,
                Description = "Tổ hợp 6 sân cỏ nhân tạo đạt chuẩn FIFA, hệ thống thoát nước chuẩn và đèn LED ban đêm rực rỡ.",
                Hotline = "0918765432",
                BasePrice = 350000,
                PeakPrice = 650000,
                Rating = 4.8m,
                Amenities = "Đèn chiếu sáng ban đêm, Trọng tài, Căn tin, Giữ xe miễn phí, Khán đài cổ vũ",
                ImageUrl = "https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800",
                IsActive = true
            });
        }

        if (!context.Venues.Any(v => v.Name.Contains("D-Sport") || v.Name.Contains("D-Sports")))
        {
            venuesToAdd.Add(new Venue
            {
                SportId = 2, // Pickleball
                Name = "CLB Pickleball D-Sports Thủ Đức",
                Address = "Số 18 đường Song Hành, An Phú",
                District = "TP. Thủ Đức",
                Latitude = 10.8498000m,
                Longitude = 106.7720000m,
                Description = "Sân Pickleball mặt sân cao cấp USAPA, mái che thoáng mát, trang thiết bị hiện đại bậc nhất khu Đông.",
                Hotline = "0934567890",
                BasePrice = 120000,
                PeakPrice = 180000,
                Rating = 4.9m,
                Amenities = "Phòng thay đồ, Huấn luyện viên, Cho thuê bóng & vợt, Ghế nghỉ ngơi, Nước uống miễn phí",
                ImageUrl = "https://images.unsplash.com/photo-1599586120429-48281b6f0ece?w=800",
                IsActive = true
            });
        }

        if (!context.Venues.Any(v => v.Name.Contains("Hồ Xuân Hương")))
        {
            venuesToAdd.Add(new Venue
            {
                SportId = 4, // Bóng rổ
                Name = "Sân Bóng Rổ TT TDTT Hồ Xuân Hương",
                Address = "Số 2 Hồ Xuân Hương, Phường 6",
                District = "Quận 3",
                Latitude = 10.7742000m,
                Longitude = 106.6892000m,
                Description = "Sân bóng rổ sàn gỗ thi đấu trong nhà chuẩn FIBA, bảng rổ kính cường lực và điều hòa nhiệt độ.",
                Hotline = "0283930403",
                BasePrice = 200000,
                PeakPrice = 350000,
                Rating = 4.7m,
                Amenities = "Sàn gỗ FIBA, Máy lạnh, Phòng tắm, Căn tin dinh dưỡng, Bãi đỗ xe rộng rãi",
                ImageUrl = "https://images.unsplash.com/photo-1546519638-68e109498ffc?w=800",
                IsActive = true
            });
        }

        if (!context.Venues.Any(v => v.Name.Contains("Celadon")))
        {
            venuesToAdd.Add(new Venue
            {
                SportId = 1, // Cầu lông
                Name = "Cụm Sân Thể Thao Celadon Tân Phú",
                Address = "Số 2 đường Bờ Bao Tân Thắng, Sơn Kỳ",
                District = "Tân Phú",
                Latitude = 10.8018000m,
                Longitude = 106.6162000m,
                Description = "Khu liên hợp thể thao xanh với 10 sân cầu lông thảm PVC, không gian rộng rãi trong lòng đại đô thị Celadon.",
                Hotline = "0908889999",
                BasePrice = 110000,
                PeakPrice = 150000,
                Rating = 4.8m,
                Amenities = "Công viên xanh, Phòng thay đồ cao cấp, Khu hồi phục cơ, Căn tin, Cho thuê dụng cụ",
                ImageUrl = "https://images.unsplash.com/photo-1613918108466-292b78a8ef95?w=800",
                IsActive = true
            });
        }

        if (venuesToAdd.Count > 0)
        {
            context.Venues.AddRange(venuesToAdd);
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
                else if (venue.SportId == 2) // Pickleball
                {
                    context.SubVenues.AddRange(
                        new SubVenue { VenueId = venue.Id, Name = "Sân P1", IsActive = true },
                        new SubVenue { VenueId = venue.Id, Name = "Sân P2", IsActive = true }
                    );
                }
                else // Bóng rổ
                {
                    context.SubVenues.AddRange(
                        new SubVenue { VenueId = venue.Id, Name = "Sân Trong Nhà", IsActive = true },
                        new SubVenue { VenueId = venue.Id, Name = "Sân Ngoài Trời", IsActive = true }
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
