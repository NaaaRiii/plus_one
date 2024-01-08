function toggleModal(show) {
  const modal = document.getElementById('modal');
  if (show) {
    modal.style.display = 'block';
    document.body.style.overflow = 'hidden';
  } else {
    modal.style.display = 'none';
    document.body.style.overflow = 'auto';
  }
}

document.addEventListener('turbo:load', function() {
  const modalElement = document.getElementById('modal');
  if (!modalElement) return;

  const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
  const currentRank = parseInt(modalElement.getAttribute('data-current-rank'), 10);
  const lastRouletteRank = parseInt(modalElement.getAttribute('data-last-roulette-rank'), 10);

  console.log("Current Rank:", currentRank);
  console.log("Last Roulette Rank:", lastRouletteRank);

  if (currentRank >= 10 && Math.floor(currentRank / 10) > Math.floor(lastRouletteRank / 10)) {
    toggleModal(true);
  }
  function closeRouletteAndUpdateRank() {
    // ルーレットを閉じる
    toggleModal(false);

    // Ajaxリクエストを使ってサーバーにランク更新を通知
    fetch('/users/update_rank', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken
      },
      body: JSON.stringify({ new_rank: currentRank })
    })
  }

  // モーダルの閉じるボタンにイベントリスナーを追加
  document.querySelector('.close-button').addEventListener('click', closeRouletteAndUpdateRank);
});