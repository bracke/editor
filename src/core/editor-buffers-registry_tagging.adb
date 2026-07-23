with Ada.Containers.Vectors;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Buffers.Registry_Tagging is

   function Index_Of
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Natural
   is
   begin
      if Registry.Items.Is_Empty then
         return Natural'Last;
      end if;

      for I in Registry.Items.First_Index .. Registry.Items.Last_Index loop
         if Registry.Items (I).Id = Id then
            return I;
         end if;
      end loop;

      return Natural'Last;
   end Index_Of;

   function Trimmed_Group_Name (Name : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Name, Ada.Strings.Both);
   end Trimmed_Group_Name;

   function Trimmed_Buffer_Label (Label : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Label, Ada.Strings.Both);
   end Trimmed_Buffer_Label;

   function Trimmed_Buffer_Note (Note : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Note, Ada.Strings.Both);
   end Trimmed_Buffer_Note;

   function Is_Buffer_Pinned
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Boolean
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      return I /= Natural'Last and then Registry.Items (I).Pinned;
   end Is_Buffer_Pinned;

   function Has_Buffer_Label
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Boolean
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      return I /= Natural'Last and then Registry.Items (I).Has_Label;
   end Has_Buffer_Label;

   function Buffer_Label
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return String
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      if I = Natural'Last or else not Registry.Items (I).Has_Label then
         return "";
      end if;
      return To_String (Registry.Items (I).Label);
   end Buffer_Label;

   procedure Set_Buffer_Label
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id;
      Label    : String)
   is
      I : constant Natural := Index_Of (Registry, Id);
      Trimmed : constant String := Trimmed_Buffer_Label (Label);
   begin
      if I /= Natural'Last then
         if Trimmed'Length = 0 then
            Clear_Buffer_Label (Registry, Id);
         elsif Trimmed'Length <= Max_Buffer_Label_Length then
            Registry.Items (I).Has_Label := True;
            Registry.Items (I).Label := To_Unbounded_String (Trimmed);
         end if;
      end if;
   end Set_Buffer_Label;

   procedure Clear_Buffer_Label
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id)
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      if I /= Natural'Last then
         Registry.Items (I).Has_Label := False;
         Registry.Items (I).Label := Null_Unbounded_String;
      end if;
   end Clear_Buffer_Label;

   function Has_Buffer_Note
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Boolean
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      return I /= Natural'Last and then Registry.Items (I).Has_Note;
   end Has_Buffer_Note;

   function Buffer_Note
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return String
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      if I = Natural'Last or else not Registry.Items (I).Has_Note then
         return "";
      end if;
      return To_String (Registry.Items (I).Note);
   end Buffer_Note;

   procedure Set_Buffer_Note
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id;
      Note     : String)
   is
      I : constant Natural := Index_Of (Registry, Id);
      Trimmed : constant String := Trimmed_Buffer_Note (Note);
   begin
      if I /= Natural'Last then
         if Trimmed'Length = 0 then
            Clear_Buffer_Note (Registry, Id);
         elsif Trimmed'Length <= Max_Buffer_Note_Length then
            Registry.Items (I).Has_Note := True;
            Registry.Items (I).Note := To_Unbounded_String (Trimmed);
         end if;
      end if;
   end Set_Buffer_Note;

   procedure Clear_Buffer_Note
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id)
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      if I /= Natural'Last then
         Registry.Items (I).Has_Note := False;
         Registry.Items (I).Note := Null_Unbounded_String;
      end if;
   end Clear_Buffer_Note;

   function Has_Buffer_Group
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Boolean
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      return I /= Natural'Last and then Registry.Items (I).Has_Group;
   end Has_Buffer_Group;

   function Buffer_Group
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return String
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      if I = Natural'Last or else not Registry.Items (I).Has_Group then
         return "";
      end if;
      return To_String (Registry.Items (I).Group);
   end Buffer_Group;

   function Group_Exists (Registry : Buffer_Registry; Name : String) return Boolean is
      Trimmed : constant String := Trimmed_Group_Name (Name);
   begin
      for Item of Registry.Items loop
         if Item.Has_Group and then To_String (Item.Group) = Trimmed then
            return True;
         end if;
      end loop;
      return False;
   end Group_Exists;

   procedure Normalize_Active_Buffer_Group (Registry : in out Buffer_Registry) is
   begin
      if Registry.Has_Active_Group
        and then not Group_Exists (Registry, To_String (Registry.Active_Group))
      then
         Registry.Has_Active_Group := False;
         Registry.Active_Group := Null_Unbounded_String;
      end if;
   end Normalize_Active_Buffer_Group;

   procedure Assign_Buffer_Group
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id;
      Name     : String)
   is
      I : constant Natural := Index_Of (Registry, Id);
      Trimmed : constant String := Trimmed_Group_Name (Name);
   begin
      if I /= Natural'Last and then Trimmed'Length > 0 then
         Registry.Items (I).Has_Group := True;
         Registry.Items (I).Group := To_Unbounded_String (Trimmed);
      end if;
   end Assign_Buffer_Group;

   procedure Clear_Buffer_Group
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id)
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      if I /= Natural'Last then
         Registry.Items (I).Has_Group := False;
         Registry.Items (I).Group := Null_Unbounded_String;
         Normalize_Active_Buffer_Group (Registry);
      end if;
   end Clear_Buffer_Group;

   function Has_Buffer_Groups
     (Registry : Buffer_Registry) return Boolean
   is
   begin
      for Item of Registry.Items loop
         if Item.Has_Group then
            return True;
         end if;
      end loop;
      return False;
   end Has_Buffer_Groups;

   function Has_Active_Buffer_Group
     (Registry : Buffer_Registry) return Boolean
   is
   begin
      return Registry.Has_Active_Group;
   end Has_Active_Buffer_Group;

   function Active_Buffer_Group
     (Registry : Buffer_Registry) return String
   is
   begin
      if not Registry.Has_Active_Group then
         return "";
      end if;
      return To_String (Registry.Active_Group);
   end Active_Buffer_Group;

   function First_Buffer_In_Group
     (Registry : Buffer_Registry;
      Name     : String) return Buffer_Id
   is
      Trimmed : constant String := Trimmed_Group_Name (Name);
   begin
      if Trimmed'Length = 0 then
         return No_Buffer;
      end if;

      for Item of Registry.Items loop
         if Item.Has_Group and then To_String (Item.Group) = Trimmed then
            return Item.Id;
         end if;
      end loop;

      return No_Buffer;
   end First_Buffer_In_Group;

   procedure Set_Active_Buffer_Group
     (Registry : in out Buffer_Registry;
      Name     : String)
   is
      Trimmed : constant String := Trimmed_Group_Name (Name);
   begin
      if Trimmed'Length > 0 and then Group_Exists (Registry, Trimmed) then
         Registry.Has_Active_Group := True;
         Registry.Active_Group := To_Unbounded_String (Trimmed);
      end if;
   end Set_Active_Buffer_Group;

   procedure Clear_Active_Buffer_Group
     (Registry : in out Buffer_Registry)
   is
   begin
      Registry.Has_Active_Group := False;
      Registry.Active_Group := Null_Unbounded_String;
   end Clear_Active_Buffer_Group;

   procedure Cycle_Active_Buffer_Group
     (Registry : in out Buffer_Registry;
      Forward  : Boolean)
   is
      package Name_Vectors is new Ada.Containers.Vectors
        (Index_Type => Natural, Element_Type => Unbounded_String);
      Names : Name_Vectors.Vector;
      Current : constant String := Active_Buffer_Group (Registry);
      Current_Index : Natural := Natural'Last;
   begin
      for Item of Registry.Items loop
         if Item.Has_Group then
            declare
               Name : constant String := To_String (Item.Group);
               Seen : Boolean := False;
            begin
               for Existing of Names loop
                  if To_String (Existing) = Name then
                     Seen := True;
                  end if;
               end loop;
               if not Seen then
                  Names.Append (Item.Group);
               end if;
            end;
         end if;
      end loop;
      if Names.Is_Empty then
         return;
      end if;
      for I in Names.First_Index .. Names.Last_Index loop
         if To_String (Names (I)) = Current then
            Current_Index := I;
         end if;
      end loop;
      if Current_Index = Natural'Last then
         Registry.Active_Group := Names (Names.First_Index);
      elsif Forward then
         if Current_Index = Names.Last_Index then
            Registry.Active_Group := Names (Names.First_Index);
         else
            Registry.Active_Group := Names (Current_Index + 1);
         end if;
      else
         if Current_Index = Names.First_Index then
            Registry.Active_Group := Names (Names.Last_Index);
         else
            Registry.Active_Group := Names (Current_Index - 1);
         end if;
      end if;
      Registry.Has_Active_Group := True;
   end Cycle_Active_Buffer_Group;

   procedure Pin_Buffer
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id)
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      if I /= Natural'Last then
         Registry.Items (I).Pinned := True;
      end if;
   end Pin_Buffer;

   procedure Unpin_Buffer
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id)
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      if I /= Natural'Last then
         Registry.Items (I).Pinned := False;
      end if;
   end Unpin_Buffer;

   procedure Toggle_Buffer_Pin
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id)
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      if I /= Natural'Last then
         Registry.Items (I).Pinned := not Registry.Items (I).Pinned;
      end if;
   end Toggle_Buffer_Pin;

end Editor.Buffers.Registry_Tagging;
