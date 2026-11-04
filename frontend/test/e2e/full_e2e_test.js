const { chromium } = require('C:/Users/ASUS/AppData/Roaming/npm/node_modules/@playwright/cli/node_modules/playwright-core');
const fs = require('fs');

async function sleep(ms) {
  return new Promise(res => setTimeout(res, ms));
}

(async () => {
  const browser = await chromium.launch({ channel: 'msedge', headless: true });
  const context = await browser.newContext({
    viewport: { width: 412, height: 890 },
    isMobile: true,
    hasTouch: true,
  });
  const page = await context.newPage();

  const logs = [];
  const errors = [];
  const networkFails = [];

  page.on('console', msg => {
    const text = `[${msg.type().toUpperCase()}] ${msg.text()}`;
    logs.push(text);
    if (msg.type() === 'error') {
      errors.push(text);
    }
  });

  page.on('pageerror', err => {
    errors.push(`[PAGE ERROR] ${err.message}\n${err.stack}`);
  });

  page.on('requestfailed', req => {
    networkFails.push(`[NET FAIL] ${req.method()} ${req.url()} (${req.failure()?.errorText})`);
  });

  console.log('--- BƯỚC 1: KHỞI TẠO VÀ VÀO APP ---');
  await page.goto('http://localhost:3000', { waitUntil: 'networkidle' });
  await sleep(3500);

  // Kích hoạt semantics
  await page.evaluate(() => {
    const ph = document.querySelector('flt-semantics-placeholder');
    if (ph) ph.click();
  });
  await sleep(1000);

  // Bấm "Khám phá ngay (Khách vãng lai)"
  console.log('Bấm "Khám phá ngay (Khách vãng lai)" tại (206, 782)...');
  await page.mouse.click(206, 782);
  await sleep(3000);
  await page.screenshot({ path: 'test_1_home.png' });

  // Helper để lấy danh sách semantic elements
  async function getElements() {
    return await page.evaluate(() => {
      const res = [];
      document.querySelectorAll('flt-semantics, [role], input').forEach(el => {
        const text = (el.innerText || el.getAttribute('aria-label') || '').trim();
        const role = el.getAttribute('role') || '';
        const rect = el.getBoundingClientRect();
        if (text && rect.width > 0 && rect.height > 0) {
          res.push({
            role,
            text,
            x: Math.round(rect.x + rect.width / 2),
            y: Math.round(rect.y + rect.height / 2),
            w: Math.round(rect.width),
            h: Math.round(rect.height)
          });
        }
      });
      return res;
    });
  }

  console.log('--- BƯỚC 2: KIỂM TRA BỘ LỌC DANH MỤC THỂ THAO (FILTER CATEGORY) ---');
  let elements = await getElements();
  // Bấm filter Cầu lông (khoảng x=180, y=360)
  const badmintonChip = elements.find(e => e.text === 'Cầu lông');
  if (badmintonChip) {
    console.log(`Bấm lọc "Cầu lông" tại (${badmintonChip.x}, ${badmintonChip.y})...`);
    await page.mouse.click(badmintonChip.x, badmintonChip.y);
  } else {
    await page.mouse.click(175, 360);
  }
  await sleep(2000);
  await page.screenshot({ path: 'test_2_filter_badminton.png' });

  // Bấm filter Pickleball
  elements = await getElements();
  const pickleballChip = elements.find(e => e.text === 'Pickleball');
  if (pickleballChip) {
    console.log(`Bấm lọc "Pickleball" tại (${pickleballChip.x}, ${pickleballChip.y})...`);
    await page.mouse.click(pickleballChip.x, pickleballChip.y);
  } else {
    await page.mouse.click(275, 360);
  }
  await sleep(2000);
  await page.screenshot({ path: 'test_3_filter_pickleball.png' });

  // Bấm filter Tất cả
  elements = await getElements();
  const allChip = elements.find(e => e.text === 'Tất cả');
  if (allChip) {
    console.log(`Bấm "Tất cả" tại (${allChip.x}, ${allChip.y})...`);
    await page.mouse.click(allChip.x, allChip.y);
    await sleep(1500);
  }

  console.log('--- BƯỚC 3: KIỂM TRA TÌM KIẾM SÂN (SEARCH) ---');
  // Bấm vào ô tìm kiếm (khoảng x=200, y=180)
  const searchEl = elements.find(e => e.text.includes('Tìm kiếm sân'));
  if (searchEl) {
    console.log(`Bấm ô tìm kiếm tại (${searchEl.x}, ${searchEl.y})...`);
    await page.mouse.click(searchEl.x, searchEl.y);
  } else {
    await page.mouse.click(200, 180);
  }
  await sleep(1000);
  await page.keyboard.type('Thủ Đức');
  await sleep(2000);
  await page.screenshot({ path: 'test_4_search_thuduc.png' });

  // Xóa nội dung tìm kiếm
  for (let i = 0; i < 15; i++) {
    await page.keyboard.press('Backspace');
  }
  await sleep(1500);

  console.log('--- BƯỚC 4: BẤM NÚT "ĐẶT SÂN NGAY" VÀO CHI TIẾT SÂN ---');
  elements = await getElements();
  const bookNowBtn = elements.find(e => e.text.includes('Đặt Sân Ngay'));
  if (bookNowBtn) {
    console.log(`Bấm "Đặt Sân Ngay" tại (${bookNowBtn.x}, ${bookNowBtn.y})...`);
    await page.mouse.click(bookNowBtn.x, bookNowBtn.y);
  } else {
    console.log('Fallback bấm nút Đặt Sân Ngay tại (320, 850)...');
    await page.mouse.click(320, 850);
  }
  await sleep(3500);
  await page.screenshot({ path: 'test_5_venue_detail.png' });

  // Kiểm tra chi tiết sân
  elements = await getElements();
  console.log(`Số phần tử trên VenueDetailScreen: ${elements.length}`);
  elements.slice(0, 15).forEach(e => console.log('  [VenueDetail]', e.text.slice(0, 40)));

  // Bấm nút quay lại (Back button khoảng x=25, y=45)
  console.log('Bấm nút quay lại màn hình Home...');
  await page.mouse.click(25, 45);
  await sleep(2500);

  console.log('--- BƯỚC 5: CHUYỂN QUA TAB 1 (TÌM KÈO - MATCH FEED) ---');
  // Bottom bar: Tab "Tìm kèo" tại khoảng x=155, y=940 hoặc 850
  elements = await getElements();
  const matchTab = elements.find(e => e.text === 'Tìm kèo');
  if (matchTab) {
    console.log(`Bấm tab "Tìm kèo" tại (${matchTab.x}, ${matchTab.y})...`);
    await page.mouse.click(matchTab.x, matchTab.y);
  } else {
    await page.mouse.click(150, 940);
  }
  await sleep(3000);
  await page.screenshot({ path: 'test_6_match_feed.png' });
  elements = await getElements();
  console.log(`Số phần tử trên MatchFeedScreen: ${elements.length}`);
  elements.slice(0, 15).forEach(e => console.log('  [MatchFeed]', e.text.slice(0, 40)));

  console.log('--- BƯỚC 6: CHUYỂN QUA TAB 2 (VÉ CỦA TÔI - MY TICKETS) ---');
  const ticketsTab = elements.find(e => e.text === 'Vé của tôi');
  if (ticketsTab) {
    console.log(`Bấm tab "Vé của tôi" tại (${ticketsTab.x}, ${ticketsTab.y})...`);
    await page.mouse.click(ticketsTab.x, ticketsTab.y);
  } else {
    await page.mouse.click(250, 940);
  }
  await sleep(3000);
  await page.screenshot({ path: 'test_7_my_tickets.png' });
  elements = await getElements();
  console.log(`Số phần tử trên MyTicketsScreen: ${elements.length}`);
  elements.slice(0, 15).forEach(e => console.log('  [Tickets]', e.text.slice(0, 40)));

  console.log('--- BƯỚC 7: CHUYỂN QUA TAB 3 (TÀI KHOẢN - PROFILE) ---');
  const profileTab = elements.find(e => e.text === 'Tài khoản');
  if (profileTab) {
    console.log(`Bấm tab "Tài khoản" tại (${profileTab.x}, ${profileTab.y})...`);
    await page.mouse.click(profileTab.x, profileTab.y);
  } else {
    await page.mouse.click(350, 940);
  }
  await sleep(3000);
  await page.screenshot({ path: 'test_8_profile.png' });
  elements = await getElements();
  console.log(`Số phần tử trên ProfileScreen: ${elements.length}`);
  elements.slice(0, 15).forEach(e => console.log('  [Profile]', e.text.slice(0, 40)));

  // Bấm Đăng nhập từ Profile Screen
  console.log('--- BƯỚC 8: BẤM ĐĂNG NHẬP / FORM AUTH ---');
  const loginBtn = elements.find(e => e.text.includes('Đăng nhập') || e.text.includes('Đăng ký'));
  if (loginBtn) {
    console.log(`Bấm nút đăng nhập tại (${loginBtn.x}, ${loginBtn.y})...`);
    await page.mouse.click(loginBtn.x, loginBtn.y);
    await sleep(3000);
    await page.screenshot({ path: 'test_9_login_screen.png' });

    // Kiểm tra form đăng nhập
    elements = await getElements();
    console.log(`Số phần tử trên LoginScreen: ${elements.length}`);
    elements.slice(0, 20).forEach(e => console.log('  [Login]', e.text.slice(0, 40)));
  }

  // Tổng hợp kết quả
  const finalReport = {
    totalLogs: logs.length,
    errorsCount: errors.length,
    errors: errors,
    networkFailsCount: networkFails.length,
    networkFails: networkFails,
    recentLogs: logs.slice(-30),
  };

  fs.writeFileSync('full_e2e_report.json', JSON.stringify(finalReport, null, 2));

  console.log('\n========================================');
  console.log('          KẾT QUẢ KIỂM THỬ TOÀN DIỆN      ');
  console.log('========================================');
  console.log(`Tổng số lỗi Console / Page Error: ${errors.length}`);
  if (errors.length > 0) {
    errors.forEach((err, idx) => console.log(` [Lỗi ${idx + 1}]: ${err}`));
  } else {
    console.log('Không phát hiện lỗi Console hoặc Crash nào!');
  }
  console.log(`Tổng số lỗi Request Network: ${networkFails.length}`);
  if (networkFails.length > 0) {
    networkFails.forEach((req, idx) => console.log(` [NetFail ${idx + 1}]: ${req}`));
  } else {
    console.log('Tất cả API requests hoạt động trơn tru 100%!');
  }

  await browser.close();
  console.log('Đã hoàn tất toàn bộ kịch bản kiểm thử E2E!');
})();
