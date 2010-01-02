unit m_font_class;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_module, DGLOpenGL;

type
  TModuleFontClass = class(TBasicModule)
    public
      (**
        * Write out some text
        *@param the text
        *@param font size (pixels)
        *@param left margin (pixels)
        *@param top margin (pixels)
        *@param red (0.0 - 1.0)
        *@param green (0.0 - 1.0)
        *@param blue (0.0 - 1.0)
        *@param alpha (0.0 - 1.0)
        *@param font flags
        *)
      procedure Write(Text: String; Size, Left, Top: GLFLoat; R, G, B, A: GLFloat; Flags: Byte); virtual abstract;

      (**
        * Calculate the width of a text
        *@param The text
        *@param Font size
        *@return width in pixels
        *)
      function CalculateTextWidth(text: String; Size: Integer): Integer; virtual abstract;
    end;

const
  FONT_BOLD = 1;
  FONT_ITALIC = 2;
  FONT_UNDERLINED = 4;
  FONT_STRIKED = 8;
  FONT_OVERLINED = 16;
  FONT_SUPERSCRIPT = 32;
  FONT_SUBSCRIPT = 64;
  FONT_SMALLCAPS = 128;

implementation

end.

