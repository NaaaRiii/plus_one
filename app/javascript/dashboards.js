document.addEventListener('turbo:render', function() {
  console.log('おk');
  let modal = document.getElementById('modal');
  let userRank = parseInt(modal.getAttribute('data-user-rank'), 10);
  let closeButton = document.getElementsByClassName('close-button')[0];

  // モーダルを表示する条件を設定
  if (userRank >= 10 && userRank % 10 > 0) {
    modal.style.display = 'block';
  }

  // 閉じるボタンでモーダルを非表示にする
  closeButton.onclick = function() {
    modal.style.display = 'none';
  };

  // モーダルの外側をクリックしても閉じる
  window.onclick = function(event) {
    if (event.target == modal) {
      modal.style.display = 'none';
    }
  };
});