#include <string.h>
#include <sys/socket.h>

int send_fd (int s, int fd)
{
  struct msghdr msg = {0};
  char buf[CMSG_SPACE(sizeof(int))];
  memset(buf, '\0', sizeof(buf));
  struct iovec io = { .iov_base = "", .iov_len = 1};

  msg.msg_iov        = &io;
  msg.msg_iovlen     = 1;
  msg.msg_control    = buf;
  msg.msg_controllen = sizeof(buf);

  struct cmsghdr *cmsg = CMSG_FIRSTHDR(&msg);
  cmsg->cmsg_len   = CMSG_LEN(sizeof(int));
  cmsg->cmsg_type  = SCM_RIGHTS;
  cmsg->cmsg_level = SOL_SOCKET;

  memmove(CMSG_DATA(cmsg), &fd, sizeof(int));
  msg.msg_controllen = cmsg->cmsg_len;

  return (sendmsg(s, &msg, 0));
}

int recv_fd (int s, int *fd) {
  struct msghdr msg = {0};

  char mbuf[1];
  char cbuf[CMSG_SPACE(sizeof(int))];
  struct iovec io = { .iov_base = mbuf, .iov_len = sizeof(mbuf)};

  msg.msg_iov     = &io;
  msg.msg_iovlen  = 1;
  msg.msg_control    = cbuf;
  msg.msg_controllen = sizeof(cbuf);
  if (recvmsg(s, &msg, 0) < 0)
  { return(-1); }

  struct cmsghdr *cmsg = CMSG_FIRSTHDR(&msg);
  memmove(fd, CMSG_DATA(cmsg), sizeof(int));
  return(0);
}
