## Little helpers for rzmq:
send_socket_string <- function(socket, data, send.more=FALSE) {
  rzmq::send.socket(socket, charToRaw(data), send.more=send.more,
                    serialize=FALSE)
}
receive_socket_string <- function(socket, ...) {
  rawToChar(rzmq::receive.socket(socket, unserialize=FALSE, ...))
}
send_multipart_string <- function(socket, parts) {
  for (part in parts[seq_len(length(parts) - 1L)]) {
    send_socket_string(socket, part, send.more=TRUE)
  }
  send_socket_string(socket, parts[[length(parts)]], send.more=FALSE)
}
receive_multipart_string <- function(socket) {
  vapply(rzmq::receive.multipart(socket), rawToChar, character(1))
}
