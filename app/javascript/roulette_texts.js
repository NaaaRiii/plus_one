document.addEventListener('turbo:load', function() {
  const editButton = document.getElementById('edit-text-button');
  const editForm = document.getElementById('edit-roulette-text-form');

  if (editButton && editForm) {
    editButton.addEventListener('click', function() {
      editForm.style.display = 'block';
    });
  }
});


document.addEventListener('turbolinks:load', function() {
  const form = document.getElementById('edit-roulette-text-form');
  if (form) {
    form.addEventListener('submit', function(event) {
      form.querySelector('.roulette-text').value = '';
    });
  }
});

