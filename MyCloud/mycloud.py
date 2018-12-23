#!/usr/bin/env python3

import pprint


class ComputeInstance:
   def __init__(self, id, name, cur_state,
                priv_dns, priv_ip,
                pub_dns, pub_ip):
      self.id = id
      self,name = name
      self.state = cur_state
      self.priv_dns = priv_dns
      self.priv_ip = priv_ip
      self.pub_dns = pub_dns
      self.pub_ip = pub_ip


#if __name__ == "__main__":
