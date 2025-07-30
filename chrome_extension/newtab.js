async function loadContent() {
  const adviceEl = document.getElementById('advice');
  try {
    const res = await fetch('https://fucking-great-advice.ru/api/random');
    const data = await res.json();
    adviceEl.textContent = data.text || data.message || 'No advice available.';
  } catch (e) {
    adviceEl.textContent = 'Could not load advice.';
  }

  try {
    const imgUrl = 'https://minimalistic-wallpaper.demolab.com/?random'; // раньше был https://minimalistic-wallpaper.demolab.com/?random
    document.body.style.backgroundImage = `url('${imgUrl}')`;
  } catch (e) {
    // ignore image errors
  }
}

document.addEventListener('DOMContentLoaded', loadContent);
