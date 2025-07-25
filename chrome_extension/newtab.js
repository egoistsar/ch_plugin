async function loadContent() {
  const adviceEl = document.getElementById('advice');
  try {
    const res = await fetch('https://api.adviceslip.com/advice');
    const data = await res.json();
    adviceEl.textContent = data.slip.advice;
  } catch (e) {
    adviceEl.textContent = 'Could not load advice.';
  }

  try {
    const imgUrl = 'https://source.unsplash.com/random/1920x1080';
    document.body.style.backgroundImage = `url('${imgUrl}')`;
  } catch (e) {
    // ignore image errors
  }
}

document.addEventListener('DOMContentLoaded', loadContent);
