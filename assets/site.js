const header = document.querySelector(".site-header");
const toast = document.querySelector(".toast");
const year = document.querySelector("[data-year]");
let toastTimer;

if (year) {
  year.textContent = String(new Date().getFullYear());
}

function showToast(message) {
  if (!toast) return;

  toast.textContent = message;
  toast.classList.add("is-visible");
  clearTimeout(toastTimer);
  toastTimer = window.setTimeout(() => {
    toast.classList.remove("is-visible");
  }, 2200);
}

function setHeaderState() {
  if (!header) return;
  header.classList.toggle("is-scrolled", window.scrollY > 8);
}

window.addEventListener("scroll", setHeaderState, { passive: true });
setHeaderState();

document.querySelectorAll("[data-copy-target]").forEach((button) => {
  button.addEventListener("click", async () => {
    const target = document.querySelector(button.dataset.copyTarget);
    const value = target?.innerText.trim();

    if (!value) return;

    try {
      await navigator.clipboard.writeText(value);
      showToast("Команда скопирована");
    } catch {
      const fallback = document.createElement("textarea");
      fallback.value = value;
      fallback.setAttribute("readonly", "");
      fallback.style.position = "fixed";
      fallback.style.opacity = "0";
      document.body.appendChild(fallback);
      fallback.select();
      document.execCommand("copy");
      fallback.remove();
      showToast("Команда скопирована");
    }
  });
});

document.querySelectorAll("[aria-disabled='true']").forEach((link) => {
  link.addEventListener("click", (event) => {
    event.preventDefault();
    showToast(link.dataset.message || "Ссылка появится позже");
  });
});
