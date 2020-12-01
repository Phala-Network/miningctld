module AppPlugin
  def empty_fail!
    res.status = 403
    res.write ''
  end
end
