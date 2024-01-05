//document.addEventListener('turbo:render', function() {
//  console.log('おk');
//  let modal = document.getElementById('modal');
//  let userRank = parseInt(modal.getAttribute('data-user-rank'), 10);
//  let closeButton = document.getElementsByClassName('close-button')[0];

//  // モーダルを表示する条件を設定
//  if (userRank >= 10 && userRank % 10 > 0) {
//    modal.style.display = 'block';
//  }

//  // 閉じるボタンでモーダルを非表示にする
//  closeButton.onclick = function() {
//    modal.style.display = 'none';
//  };

//  // モーダルの外側をクリックしても閉じる
//  window.onclick = function(event) {
//    if (event.target == modal) {
//      modal.style.display = 'none';
//    }
//  };
//});

//document.addEventListener('turbo:render', function() {
//  function toggleModal(show) {
//    const modal = document.getElementById('modal');
//    if (show) {
//      modal.style.display = 'block';
//      document.body.style.overflow = 'hidden';
//    } else {
//      modal.style.display = 'none';
//      document.body.style.overflow = 'auto';
//    }
//  }
//  toggleModal(true);
//});

//document.addEventListener('turbo:load', function() {
//  const closeButton = document.querySelector('.close-button');
//    if (closeButton) {
//      closeButton.addEventListener('click', () => {
//        toggleModal(false);
//      });
//    }
//});


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


//document.addEventListener('turbo:load', function() {
//  const modalElement = document.getElementById('modal');
//  const currentRank = parseInt(modalElement.getAttribute('data-current-rank'), 10);
//  if (currentRank >= 10 && currentRank % 10 > 0) {
//    toggleModal(true);
//  }
//});

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
    // ... 以下、エラーハンドリングなど ...
  }

  // モーダルの閉じるボタンにイベントリスナーを追加
  document.querySelector('.close-button').addEventListener('click', closeRouletteAndUpdateRank);
});



//別々にしないと閉じない
//document.addEventListener('turbo:load', function() {
//  const closeButton = document.querySelector('.close-button');
//  closeButton.addEventListener('click', () => {
//    toggleModal(false);
//  });
//});

//document.addEventListener('turbo:load', function() {
//  const closeButton = document.querySelector('.close-button');
//  if (!closeButton) return;

//  closeButton.addEventListener('click', () => {
//    toggleModal(false);
//  });
//});

//function closeRouletteAndUpdateRank() {
//  // ルーレットを閉じる
//  toggleModal(false);

//  // Ajaxリクエストを使ってサーバーにランク更新を通知
//  fetch('/path/to/update/rank', {
//    method: 'POST',
//    headers: {
//      'Content-Type': 'application/json',
//      'X-CSRF-Token': csrfToken // CSRFトークンを設定
//    },
//    body: JSON.stringify({ new_rank: currentRank })
//  }).then(response => {
//    if (!response.ok) {
//      throw new Error('Network response was not ok');
//    }
//    return response.json();
//  }).then(data => {
//    console.log('Rank updated:', data);
//  }).catch(error => {
//    console.error('Error updating rank:', error);
//  });
//}

