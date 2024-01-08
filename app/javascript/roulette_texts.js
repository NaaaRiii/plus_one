document.addEventListener('turbo:load', function() {
  const editButton = document.getElementById('edit-text-button');
  const editForm = document.getElementById('edit-roulette-text-form');

  if (editButton && editForm) {
    editButton.addEventListener('click', function() {
      editForm.style.display = 'block'; // フォームを表示
    });
  } else {
    console.error('Edit button or form not found');
  }
});
