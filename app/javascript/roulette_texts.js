document.addEventListener('turbo:load', function() {
  const editButton = document.getElementById('edit-text-button');
  const editForm = document.getElementById('edit-roulette-text-form');

  if (editButton && editForm) {
    editButton.addEventListener('click', function() {
      editForm.style.display = 'block'; // フォームを表示
    });
  }
});


document.addEventListener('turbolinks:load', function() {
  const form = document.getElementById('edit-roulette-text-form');
  if (form) {
    form.addEventListener('submit', function(event) {
      // ここで非同期通信のロジックを実装
      // 非同期通信が成功したら、以下の行でテキストフィールドをリセット
      form.querySelector('.roulette-text').value = '';
    });
  }
});

