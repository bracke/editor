with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Semantic_Diagnostic_Snapshot_Guards is

   pragma Suppress (Overflow_Check);

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 131) + B + 41) mod 1_000_000_007;
   end Mix;

   function Key_Fingerprint (Key : Diagnostic_Snapshot_Key) return Natural is
      H : Natural := 0;
      S : constant String := To_String (Key.Path);
   begin
      for C of S loop
         H := Mix (H, Character'Pos (C));
      end loop;
      H := Mix (H, Key.Buffer_Token);
      H := Mix (H, Key.Buffer_Revision);
      H := Mix (H, Key.Lifecycle_Generation);
      H := Mix (H, Key.Request_Token);
      H := Mix (H, Key.Analysis_Fingerprint);
      return H;
   end Key_Fingerprint;

   function Make_Key
     (Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Request_Token        : Natural;
      Analysis_Fingerprint : Natural) return Diagnostic_Snapshot_Key
   is
   begin
      return
        (Path                 => To_Unbounded_String (Path),
         Buffer_Token         => Buffer_Token,
         Buffer_Revision      => Buffer_Revision,
         Lifecycle_Generation => Lifecycle_Generation,
         Request_Token        => Request_Token,
         Analysis_Fingerprint => Analysis_Fingerprint);
   end Make_Key;

   function Validate
     (Produced : Diagnostic_Snapshot_Key;
      Current  : Diagnostic_Snapshot_Key) return Diagnostic_Snapshot_Status
   is
   begin
      if To_String (Produced.Path) /= To_String (Current.Path) then
         return Diagnostic_Snapshot_Path_Mismatch;
      elsif Produced.Buffer_Token /= Current.Buffer_Token then
         return Diagnostic_Snapshot_Buffer_Mismatch;
      elsif Produced.Buffer_Revision /= Current.Buffer_Revision then
         return Diagnostic_Snapshot_Revision_Mismatch;
      elsif Produced.Lifecycle_Generation /= Current.Lifecycle_Generation then
         return Diagnostic_Snapshot_Lifecycle_Mismatch;
      elsif Produced.Request_Token /= Current.Request_Token then
         return Diagnostic_Snapshot_Request_Token_Mismatch;
      elsif Produced.Analysis_Fingerprint /= Current.Analysis_Fingerprint then
         return Diagnostic_Snapshot_Analysis_Fingerprint_Mismatch;
      else
         return Diagnostic_Snapshot_Current;
      end if;
   end Validate;

   function Build
     (Produced_Key : Diagnostic_Snapshot_Key;
      Current_Key  : Diagnostic_Snapshot_Key;
      Projection   : Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Model)
      return Guarded_Semantic_Diagnostic_Model
   is
      Model : Guarded_Semantic_Diagnostic_Model;
   begin
      Model.Produced_Key := Produced_Key;
      Model.Current_Key := Current_Key;
      Model.Guard_Status := Validate (Produced_Key, Current_Key);
      Model.Result_Fingerprint :=
        Mix (Key_Fingerprint (Produced_Key), Key_Fingerprint (Current_Key));

      if Model.Guard_Status /= Diagnostic_Snapshot_Current then
         Model.Rejected_Total :=
           Editor.Ada_Semantic_Colour_Projection.Entry_Count (Projection);
         Model.Result_Fingerprint :=
           Mix (Model.Result_Fingerprint,
                Diagnostic_Snapshot_Status'Pos (Model.Guard_Status) + 1);
         return Model;
      end if;

      for Index in 1 .. Editor.Ada_Semantic_Colour_Projection.Entry_Count (Projection) loop
         declare
            Feed_Item : constant Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Entry :=
              Editor.Ada_Semantic_Colour_Projection.Entry_At (Projection, Index);
         begin
            Model.Entries.Append (Feed_Item);
            case Feed_Item.Severity is
               when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Error =>
                  Model.Error_Total := Model.Error_Total + 1;
               when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Warning =>
                  Model.Warning_Total := Model.Warning_Total + 1;
               when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Info =>
                  Model.Info_Total := Model.Info_Total + 1;
            end case;
            Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Feed_Item.Fingerprint);
         end;
      end loop;

      return Model;
   end Build;

   function Accepted (Model : Guarded_Semantic_Diagnostic_Model) return Boolean is
   begin
      return Model.Guard_Status = Diagnostic_Snapshot_Current;
   end Accepted;

   function Rejected (Model : Guarded_Semantic_Diagnostic_Model) return Boolean is
   begin
      return Model.Guard_Status /= Diagnostic_Snapshot_Current;
   end Rejected;

   function Status
     (Model : Guarded_Semantic_Diagnostic_Model) return Diagnostic_Snapshot_Status
   is
   begin
      return Model.Guard_Status;
   end Status;

   function Entry_Count (Model : Guarded_Semantic_Diagnostic_Model) return Natural is
   begin
      return Natural (Model.Entries.Length);
   end Entry_Count;

   function Entry_At
     (Model : Guarded_Semantic_Diagnostic_Model;
      Index : Positive)
      return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Entry
   is
   begin
      if Index > Natural (Model.Entries.Length) then
         return (others => <>);
      end if;
      return Model.Entries.Element (Index);
   end Entry_At;

   function Error_Count (Model : Guarded_Semantic_Diagnostic_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : Guarded_Semantic_Diagnostic_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function Info_Count (Model : Guarded_Semantic_Diagnostic_Model) return Natural is
   begin
      return Model.Info_Total;
   end Info_Count;

   function Rejected_Entry_Count
     (Model : Guarded_Semantic_Diagnostic_Model) return Natural is
   begin
      return Model.Rejected_Total;
   end Rejected_Entry_Count;

   function Fingerprint (Model : Guarded_Semantic_Diagnostic_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
