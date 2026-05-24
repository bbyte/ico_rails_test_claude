import { render, screen, waitFor } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { LoginForm } from "./LoginForm"

jest.mock("../../api/client", () => ({
  api: {
    signIn: jest.fn(),
  },
}))

import { api } from "../../api/client"

afterEach(() => jest.resetAllMocks())

test("renders email and password fields", () => {
  render(<LoginForm onLogin={() => {}} />)
  expect(screen.getByLabelText(/email/i)).toBeInTheDocument()
  expect(screen.getByLabelText(/password/i)).toBeInTheDocument()
  expect(screen.getByRole("button", { name: /sign in/i })).toBeInTheDocument()
})

test("calls onLogin on successful sign in", async () => {
  api.signIn.mockResolvedValue({ message: "Signed in successfully" })
  const onLogin = jest.fn()
  render(<LoginForm onLogin={onLogin} />)

  await userEvent.type(screen.getByLabelText(/email/i), "alice@example.com")
  await userEvent.type(screen.getByLabelText(/password/i), "password")
  await userEvent.click(screen.getByRole("button", { name: /sign in/i }))

  await waitFor(() => expect(onLogin).toHaveBeenCalledTimes(1))
})

test("shows error message on failed sign in", async () => {
  api.signIn.mockRejectedValue(new Error("Unauthorized"))
  render(<LoginForm onLogin={() => {}} />)

  await userEvent.type(screen.getByLabelText(/email/i), "wrong@example.com")
  await userEvent.type(screen.getByLabelText(/password/i), "wrong")
  await userEvent.click(screen.getByRole("button", { name: /sign in/i }))

  await waitFor(() =>
    expect(screen.getByText(/invalid email or password/i)).toBeInTheDocument()
  )
})
