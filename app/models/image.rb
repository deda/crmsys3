class Image < ActiveRecord::Base

  belongs_to :owner, :polymorphic => true
  has_attached_file :photo, :styles => {
    :s800x600 => "800x600>",
    :s128x128 => "128x128>",
    :s64x64   => "64x64>",
    :s48x48   => "48x48>",
    :s32x32   => "32x32>"}

  #-----------------------------------------------------------------------------
  def to_xml ops={}
    return "#{'  '*(ops[:level]||0)}<image>#{encoded_photo}</image>\n"
  end

  #-----------------------------------------------------------------------------
  def self.from_xml xml
    return from_str(xml.unpack('m')[0])
  end

  #-----------------------------------------------------------------------------
  def to_vcf
    s = ''
    encoded_photo.each_line { |l| s += '  ' + l }
    return "PHOTO;BASE64:\n#{s}"
  end

  #-----------------------------------------------------------------------------
  def self.from_str str
    tempfile = Tempfile.new('crmsys')
    tempfile.write(str)
    return new(:photo => tempfile)
  end


private

  #-----------------------------------------------------------------------------
  def encoded_photo
    file = photo.to_file(:original)
    return [file.read(file.size)].pack('m')
  end

end