package body Editor.Panels is

   Current_Panels : Panel_Set;

   Default_File_Tree_Config : constant Panel_Config :=
     (Enabled              => True,
      Side                 => Left_Side,
      Default_Size         => 28,
      Minimum_Size         => 16,
      Maximum_Size         => 60,
      Splitter_Size_Pixels => 4,
      Size_Unit            => Columns,
      Resizable            => True);

   procedure Initialize_Defaults
     (Panels : in out Panel_Set)
   is
   begin
      Panels.Configs := (others => (others => <>));
      Panels.States  := (others => (others => <>));
      Panels.Resize  := (others => <>);
      Panels.Bottom_Content := Problems_Content;

      Panels.Configs (File_Tree_Panel) := Default_File_Tree_Config;
      Panels.States (File_Tree_Panel) :=
        (Visible      => True,
         Current_Size => Default_File_Tree_Config.Default_Size);

      Panels.Configs (Right_Sidebar_Panel) :=
        (Enabled              => False,
         Side                 => Right_Side,
         Default_Size         => 0,
         Minimum_Size         => 0,
         Maximum_Size         => 0,
         Splitter_Size_Pixels => 4,
         Size_Unit            => Columns,
         Resizable            => False);
      Panels.States (Right_Sidebar_Panel) :=
        (Visible => False, Current_Size => 0);

      Panels.Configs (Bottom_Panel) :=
        (Enabled              => True,
         Side                 => Bottom_Side,
         Default_Size         => 8,
         Minimum_Size         => 4,
         Maximum_Size         => 20,
         Splitter_Size_Pixels => 4,
         Size_Unit            => Rows,
         Resizable            => True);
      Panels.States (Bottom_Panel) :=
        (Visible => False, Current_Size => 8);
   end Initialize_Defaults;

   function Default_Set return Panel_Set is
      Result : Panel_Set;
   begin
      Initialize_Defaults (Result);
      return Result;
   end Default_Set;

   function Current return Panel_Set is
   begin
      return Current_Panels;
   end Current;

   procedure Set_Current
     (Panels : Panel_Set)
   is
   begin
      Current_Panels := Panels;
   end Set_Current;

   function Config
     (Panels : Panel_Set;
      Id     : Panel_Id) return Panel_Config
   is
   begin
      return Panels.Configs (Id);
   end Config;

   procedure Set_Config
     (Panels : in out Panel_Set;
      Id     : Panel_Id;
      Config : Panel_Config)
   is
   begin
      Panels.Configs (Id) := Config;
      Panels.States (Id).Current_Size := Clamp_Size
        (Config, Panels.States (Id).Current_Size);
      if not Config.Enabled then
         Panels.States (Id).Visible := False;
      end if;
   end Set_Config;

   function State
     (Panels : Panel_Set;
      Id     : Panel_Id) return Panel_State
   is
   begin
      return Panels.States (Id);
   end State;

   procedure Set_Visible
     (Panels  : in out Panel_Set;
      Id      : Panel_Id;
      Visible : Boolean)
   is
   begin
      Panels.States (Id).Visible := Visible and then Panels.Configs (Id).Enabled;
   end Set_Visible;

   function Is_Visible
     (Panels : Panel_Set;
      Id     : Panel_Id) return Boolean
   is
   begin
      return Panels.Configs (Id).Enabled and then Panels.States (Id).Visible;
   end Is_Visible;

   function Current_Size
     (Panels : Panel_Set;
      Id     : Panel_Id) return Natural
   is
   begin
      return Panels.States (Id).Current_Size;
   end Current_Size;

   function Clamp_Size
     (Config : Panel_Config;
      Size   : Natural) return Natural
   is
   begin
      if Config.Maximum_Size > 0 and then Config.Minimum_Size > Config.Maximum_Size then
         return Config.Maximum_Size;
      elsif Config.Maximum_Size > 0 and then Size > Config.Maximum_Size then
         return Config.Maximum_Size;
      elsif Size < Config.Minimum_Size then
         return Config.Minimum_Size;
      else
         return Size;
      end if;
   end Clamp_Size;

   procedure Set_Current_Size
     (Panels : in out Panel_Set;
      Id     : Panel_Id;
      Size   : Natural)
   is
   begin
      Panels.States (Id).Current_Size := Clamp_Size (Panels.Configs (Id), Size);
   end Set_Current_Size;

   function Resize_State
     (Panels : Panel_Set) return Panel_Resize_State
   is
   begin
      return Panels.Resize;
   end Resize_State;

   procedure Begin_Resize
     (Panels  : in out Panel_Set;
      Id      : Panel_Id;
      Mouse_X : Integer;
      Mouse_Y : Integer)
   is
   begin
      if not Is_Visible (Panels, Id) or else not Panels.Configs (Id).Resizable then
         Panels.Resize.Active := False;
         return;
      end if;

      Panels.Resize :=
        (Active        => True,
         Panel         => Id,
         Start_Mouse_X => Mouse_X,
         Start_Mouse_Y => Mouse_Y,
         Start_Size    => Panels.States (Id).Current_Size);
   end Begin_Resize;

   procedure Update_Resize
     (Panels      : in out Panel_Set;
      Mouse_X     : Integer;
      Mouse_Y     : Integer;
      Cell_Width  : Natural;
      Cell_Height : Natural)
   is
      Resize       : constant Panel_Resize_State := Panels.Resize;
      Cfg          : Panel_Config;
      Delta_Pixels : Integer := 0;
      Delta_Size   : Integer := 0;
      Requested    : Integer := 0;
   begin
      if not Resize.Active then
         return;
      end if;

      Cfg := Panels.Configs (Resize.Panel);

      case Cfg.Side is
         when Left_Side =>
            Delta_Pixels := Mouse_X - Resize.Start_Mouse_X;
         when Right_Side =>
            Delta_Pixels := Resize.Start_Mouse_X - Mouse_X;
         when Bottom_Side =>
            Delta_Pixels := Resize.Start_Mouse_Y - Mouse_Y;
      end case;

      case Cfg.Size_Unit is
         when Columns =>
            if Cell_Width = 0 then
               Delta_Size := 0;
            else
               Delta_Size := Delta_Pixels / Integer (Cell_Width);
            end if;
         when Rows =>
            if Cell_Height = 0 then
               Delta_Size := 0;
            else
               Delta_Size := Delta_Pixels / Integer (Cell_Height);
            end if;
         when Pixels =>
            Delta_Size := Delta_Pixels;
      end case;

      Requested := Integer (Resize.Start_Size) + Delta_Size;
      if Requested <= 0 then
         Set_Current_Size (Panels, Resize.Panel, 0);
      else
         Set_Current_Size (Panels, Resize.Panel, Natural (Requested));
      end if;
   end Update_Resize;

   procedure End_Resize
     (Panels : in out Panel_Set)
   is
   begin
      Panels.Resize.Active := False;
   end End_Resize;

   function Resize_Active
     (Panels : Panel_Set) return Boolean
   is
   begin
      return Panels.Resize.Active;
   end Resize_Active;

   procedure Set_Bottom_Content
     (Panels  : in out Panel_Set;
      Content : Bottom_Panel_Content)
   is
   begin
      Panels.Bottom_Content := Content;
   end Set_Bottom_Content;

   function Active_Bottom_Content
     (Panels : Panel_Set) return Bottom_Panel_Content
   is
   begin
      return Panels.Bottom_Content;
   end Active_Bottom_Content;

begin
   Initialize_Defaults (Current_Panels);
end Editor.Panels;
