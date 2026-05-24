const csrfToken = () =>
  document.querySelector('meta[name="csrf-token"]')?.getAttribute("content") ?? ""

async function request(path, options = {}) {
  const res = await fetch(path, {
    credentials: "include",
    headers: {
      "Content-Type": "application/json",
      "X-CSRF-Token": csrfToken(),
      ...options.headers,
    },
    ...options,
  })
  const data = await res.json().catch(() => ({}))
  if (!res.ok) throw Object.assign(new Error(data.error || res.statusText), { status: res.status, data })
  return data
}

export const api = {
  signIn: (email, password) =>
    request("/api/v1/users/sign_in", {
      method: "POST",
      body: JSON.stringify({ user: { email, password } }),
    }),

  signOut: () =>
    request("/api/v1/users/sign_out", { method: "DELETE" }),

  submitFeeds: (urls) =>
    request("/api/v1/feeds", {
      method: "POST",
      body: JSON.stringify({ urls }),
    }),

  getFeedItems: () =>
    request("/api/v1/feed_items"),
}
