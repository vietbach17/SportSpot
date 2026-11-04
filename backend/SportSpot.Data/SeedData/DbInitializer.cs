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
                AvatarUrl = "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400&q=80",
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
                ImageUrl = "https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=1200&q=80",
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
                ImageUrl = "https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=1200&q=80",
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
                ImageUrl = "https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=1200&q=80",
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
                ImageUrl = "https://images.unsplash.com/photo-1546519638-68e109498ffc?w=1200&q=80",
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
                ImageUrl = "https://images.unsplash.com/photo-1613918108466-292b78a8ef95?w=1200&q=80",
                IsActive = true
            });
        }

        if (venuesToAdd.Count > 0)
        {
            context.Venues.AddRange(venuesToAdd);
            context.SaveChanges();
        }

        SeedSubVenuesAndServices(context);
        SeedReviews(context);
        SeedNotificationsAndFavorites(context);
        UpdateRealImagesAndAvatars(context);
        SeedOpenMatchesIfEmpty(context);
    }

    private static void SeedNotificationsAndFavorites(SportSpotDbContext context)
    {
        var user = context.Users.FirstOrDefault();
        var venue = context.Venues.FirstOrDefault();
        if (user != null)
        {
            if (!context.Notifications.Any(n => n.UserId == user.Id))
            {
                context.Notifications.AddRange(
                    new Notification
                    {
                        UserId = user.Id,
                        Title = "Nhắc lịch thi đấu sắp diễn ra",
                        Message = "Trận Cầu lông tại CLB Kỳ Hòa sẽ diễn ra lúc 18:00 hôm nay. Vui lòng có mặt trước 15 phút!",
                        Type = "Reminder",
                        IsRead = false,
                        CreatedAt = DateTime.UtcNow.AddHours(-1)
                    },
                    new Notification
                    {
                        UserId = user.Id,
                        Title = "Xác nhận cọc Escrow thành công",
                        Message = "Tiền cọc của đơn đặt sân SP-782194 đang được SportSpot giữ an toàn ở trạng thái Holding.",
                        Type = "Booking",
                        IsRead = true,
                        CreatedAt = DateTime.UtcNow.AddHours(-3)
                    },
                    new Notification
                    {
                        UserId = user.Id,
                        Title = "Có kèo ghép mới gần bạn",
                        Message = "CLB Cầu Lông Kỳ Hòa vừa có 1 kèo mới trình độ Trung bình đang cần tìm thêm 1 người.",
                        Type = "Match",
                        IsRead = false,
                        CreatedAt = DateTime.UtcNow.AddDays(-1)
                    }
                );
            }

            if (venue != null && !context.FavoriteVenues.Any(f => f.UserId == user.Id && f.VenueId == venue.Id))
            {
                context.FavoriteVenues.Add(new FavoriteVenue
                {
                    UserId = user.Id,
                    VenueId = venue.Id,
                    CreatedAt = DateTime.UtcNow
                });
            }

            context.SaveChanges();
        }
    }

    private static void SeedReviews(SportSpotDbContext context)
    {
        if (!context.Reviews.Any())
        {
            var firstVenue = context.Venues.FirstOrDefault();
            var firstUser = context.Users.FirstOrDefault();
            if (firstVenue != null && firstUser != null)
            {
                context.Reviews.AddRange(
                    new Review
                    {
                        VenueId = firstVenue.Id,
                        UserId = firstUser.Id,
                        Rating = 5,
                        Comment = "Sân thảm tiêu chuẩn BWF cực êm, hệ thống đèn chống chói rất tốt. Nhân viên thân thiện!",
                        CreatedAt = DateTime.UtcNow.AddDays(-2)
                    },
                    new Review
                    {
                        VenueId = firstVenue.Id,
                        UserId = firstUser.Id,
                        Rating = 5,
                        Comment = "Cụm sân sạch sẽ, chỗ để xe ô tô rộng rãi. Đặt cọc qua app check-in QR rất nhanh gọn.",
                        CreatedAt = DateTime.UtcNow.AddDays(-1)
                    }
                );
                context.SaveChanges();
            }
        }
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
        var matches = context.OpenMatches.ToList();
        foreach (var m in matches)
        {
            if (string.IsNullOrEmpty(m.Title))
            {
                m.Title = "Kèo giao lưu cuối tuần vui vẻ phong trào";
            }
            if (string.IsNullOrEmpty(m.HostNote))
            {
                m.HostNote = "Tuyển anh em vui vẻ giao lưu, tinh thần fair-play, đến trước 10 phút khởi động!";
            }
            if (string.IsNullOrEmpty(m.HostPhone))
            {
                m.HostPhone = "0988888888";
            }
        }
        context.SaveChanges();
    }

    private static void UpdateRealImagesAndAvatars(SportSpotDbContext context)
    {
        var venues = context.Venues.ToList();
        foreach (var v in venues)
        {
            if (v.SportId == 1)
            {
                v.ImageUrl = v.Name.Contains("Celadon")
                    ? "https://images.unsplash.com/photo-1613918108466-292b78a8ef95?w=1200&q=80"
                    : "https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=1200&q=80";
            }
            else if (v.SportId == 2)
            {
                v.ImageUrl = "https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=1200&q=80";
            }
            else if (v.SportId == 3)
            {
                v.ImageUrl = v.Name.Contains("Prime")
                    ? "https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=1200&q=80"
                    : "https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=1200&q=80";
            }
            else if (v.SportId == 4)
            {
                v.ImageUrl = "https://images.unsplash.com/photo-1546519638-68e109498ffc?w=1200&q=80";
            }
        }

        var users = context.Users.ToList();
        foreach (var u in users)
        {
            if (string.IsNullOrEmpty(u.AvatarUrl))
            {
                if (u.Id == 1 || u.FullName.Contains("Host") || u.FullName.Contains("Nam"))
                    u.AvatarUrl = "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400&q=80";
                else if (u.FullName.Contains("Trang") || u.FullName.Contains("Linh") || u.FullName.Contains("Hương"))
                    u.AvatarUrl = "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&q=80";
                else
                    u.AvatarUrl = "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80";
            }
        }
        var matches = context.OpenMatches.ToList();
        foreach (var m in matches)
        {
            if (string.IsNullOrEmpty(m.Title))
            {
                m.Title = "Kèo giao lưu cuối tuần vui vẻ phong trào";
            }
            if (string.IsNullOrEmpty(m.HostNote))
            {
                m.HostNote = "Tuyển anh em vui vẻ giao lưu, tinh thần fair-play, đến trước 10 phút khởi động!";
            }
            if (string.IsNullOrEmpty(m.HostPhone))
            {
                m.HostPhone = "0988888888";
            }
        }
        context.SaveChanges();
    }

    private static void SeedOpenMatchesIfEmpty(SportSpotDbContext context)
    {
        if (!context.OpenMatches.Any())
        {
            var hostUser = context.Users.FirstOrDefault();
            var kyHoaSub = context.SubVenues.FirstOrDefault(s => s.VenueId == 1) 
                ?? context.SubVenues.FirstOrDefault();
            var dsportsSub = context.SubVenues.FirstOrDefault(s => s.VenueId == 3) 
                ?? context.SubVenues.Skip(1).FirstOrDefault();

            if (hostUser != null && kyHoaSub != null)
            {
                var booking1 = new Booking
                {
                    BookingCode = "SP-MATCH-01",
                    UserId = hostUser.Id,
                    SubVenueId = kyHoaSub.Id,
                    PlayDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(1)),
                    CourtPrice = 240000,
                    TotalPrice = 240000,
                    DepositAmount = 120000,
                    RemainingBalance = 120000,
                    BookingType = "OpenMatch",
                    Status = "Upcoming",
                    CreatedAt = DateTime.UtcNow
                };
                context.Bookings.Add(booking1);
                context.SaveChanges();

                context.BookingDetails.Add(new BookingDetail
                {
                    BookingId = booking1.Id,
                    SlotId = 10,
                    Price = 120000
                });

                context.OpenMatches.Add(new OpenMatch
                {
                    BookingId = booking1.Id,
                    HostUserId = hostUser.Id,
                    Title = "Tuyển 2 Slot Đôi Nam Nữ Giao Lưu Kỳ Hòa",
                    HostNote = "Anh em đến trước 10 phút khởi động nhé. Cầu thi đấu Hải Yến đỏ.",
                    HostPhone = "0903123456",
                    TotalExpectedPlayers = 4,
                    NeededPlayers = 4,
                    CurrentJoinedPlayers = 2,
                    CostPerPerson = 60000,
                    SkillLevel = "Trung bình khá (B+)",
                    Status = "Open",
                    CreatedAt = DateTime.UtcNow
                });
            }

            if (hostUser != null && dsportsSub != null)
            {
                var booking2 = new Booking
                {
                    BookingCode = "SP-MATCH-02",
                    UserId = hostUser.Id,
                    SubVenueId = dsportsSub.Id,
                    PlayDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(1)),
                    CourtPrice = 200000,
                    TotalPrice = 200000,
                    DepositAmount = 100000,
                    RemainingBalance = 100000,
                    BookingType = "OpenMatch",
                    Status = "Upcoming",
                    CreatedAt = DateTime.UtcNow
                };
                context.Bookings.Add(booking2);
                context.SaveChanges();

                context.BookingDetails.Add(new BookingDetail
                {
                    BookingId = booking2.Id,
                    SlotId = 5,
                    Price = 100000
                });

                context.OpenMatches.Add(new OpenMatch
                {
                    BookingId = booking2.Id,
                    HostUserId = hostUser.Id,
                    Title = "Kèo Đôi Pickleball D-Sports Tìm 1 Tay Vợt",
                    HostNote = "Kèo giao lưu buổi sáng nhẹ nhàng, có bóng Franklin X-40 sẵn.",
                    HostPhone = "0934567890",
                    TotalExpectedPlayers = 4,
                    NeededPlayers = 4,
                    CurrentJoinedPlayers = 3,
                    CostPerPerson = 50000,
                    SkillLevel = "Cơ bản (2.5 - 3.0)",
                    Status = "Open",
                    CreatedAt = DateTime.UtcNow
                });
            }

            context.SaveChanges();
        }
    }

}