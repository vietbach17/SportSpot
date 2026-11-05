-- Thêm bộ môn Tennis nếu chưa có trong bảng Sports
INSERT INTO public."Sports" ("Id", "Name", "IconUrl")
VALUES (5, 'Tennis', 'https://cdn-icons-png.flaticon.com/512/2906/2906478.png')
ON CONFLICT ("Id") DO NOTHING;

-- Thêm thiết lập kỹ năng bộ môn cho toàn bộ người chơi hiện có
INSERT INTO public."UserSkills" ("UserId", "SportId", "SkillLevel", "RatingScore", "IsVerified", "VerifiedBy", "UpdatedAt")
SELECT 
    u."Id" AS "UserId",
    s."Id" AS "SportId",
    CASE 
        WHEN s."Name" = 'Cầu lông' THEN 'Khá'
        WHEN s."Name" = 'Pickleball' THEN 'Phong trào'
        WHEN s."Name" = 'Bóng đá mini' THEN 'Phong trào'
        WHEN s."Name" = 'Bóng rổ' THEN 'Cơ bản'
        ELSE 'Phong trào'
    END AS "SkillLevel",
    CASE 
        WHEN s."Name" = 'Cầu lông' THEN 4.0
        WHEN s."Name" = 'Pickleball' THEN 3.5
        WHEN s."Name" = 'Bóng đá mini' THEN 3.5
        WHEN s."Name" = 'Bóng rổ' THEN 3.0
        ELSE 3.5
    END AS "RatingScore",
    CASE WHEN s."Name" = 'Cầu lông' THEN true ELSE false END AS "IsVerified",
    CASE WHEN s."Name" = 'Cầu lông' THEN 'CLB Cầu Lông Kỳ Hòa' ELSE NULL END AS "VerifiedBy",
    NOW() AS "UpdatedAt"
FROM public."Users" u
CROSS JOIN public."Sports" s
WHERE s."Id" IN (1, 2, 3)
ON CONFLICT ("UserId", "SportId") DO UPDATE 
SET "SkillLevel" = EXCLUDED."SkillLevel",
    "RatingScore" = EXCLUDED."RatingScore",
    "UpdatedAt" = NOW();
