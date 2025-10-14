import startest.{describe, it}
import startest/expect
import yodel/internal/path

pub fn path_tests() {
  describe("path", [
    it("formats basic path", fn() {
      path.new()
      |> path.add_segment("foo")
      |> path.add_segment("bar")
      |> path.add_index(0)
      |> path.path_to_string
      |> expect.to_equal("foo.bar[0]")
    }),
    it("formats slightly less basic path", fn() {
      path.new()
      |> path.add_segment("foo")
      |> path.add_index(9)
      |> path.add_index(17)
      |> path.add_segment("bar")
      |> path.add_index(7)
      |> path.add_segment("baz")
      |> path.add_index(42)
      |> path.path_to_string
      |> expect.to_equal("foo[9][17].bar[7].baz[42]")
    }),
  ])
}
