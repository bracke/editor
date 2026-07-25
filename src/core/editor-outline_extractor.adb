with Editor.Outline_Extractor.Snapshots;
with Editor.Outline_Extractor.Scan_Engine;

package body Editor.Outline_Extractor is

   use type Editor.Outline.Outline_Item_Kind;

   function Make_Snapshot
     (Text : String) return Buffer_Text_Snapshot
     renames Editor.Outline_Extractor.Snapshots.Make_Snapshot;

   function Make_Snapshot
     (Text         : String;
      Buffer_Label : String) return Buffer_Text_Snapshot
     renames Editor.Outline_Extractor.Snapshots.Make_Snapshot;

   function Make_Snapshot
     (Text               : String;
      Active_Buffer_Token  : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Request_Token        : Natural) return Buffer_Text_Snapshot
     renames Editor.Outline_Extractor.Snapshots.Make_Snapshot;

   function Make_Snapshot
     (Text               : String;
      Buffer_Label       : String;
      Active_Buffer_Token  : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Request_Token        : Natural) return Buffer_Text_Snapshot
     renames Editor.Outline_Extractor.Snapshots.Make_Snapshot;

   function Identity
     (Snapshot : Buffer_Text_Snapshot) return Editor.Outline.Outline_Snapshot_Identity
     renames Editor.Outline_Extractor.Snapshots.Identity;

   function Status
     (Result : Extraction_Result) return Extraction_Status
     renames Editor.Outline_Extractor.Snapshots.Status;

   function Failure
     (Result : Extraction_Result) return Extraction_Failure_Kind
     renames Editor.Outline_Extractor.Snapshots.Failure;

   function Item_Count
     (Result : Extraction_Result) return Natural
     renames Editor.Outline_Extractor.Snapshots.Item_Count;

   function Identity
     (Result : Extraction_Result) return Editor.Outline.Outline_Snapshot_Identity
     renames Editor.Outline_Extractor.Snapshots.Identity;

   function Is_Success
     (Result : Extraction_Result) return Boolean
     renames Editor.Outline_Extractor.Snapshots.Is_Success;

   function Fingerprint
     (Result : Extraction_Result) return Natural
     renames Editor.Outline_Extractor.Snapshots.Fingerprint;

   function Extract
     (Snapshot : Buffer_Text_Snapshot) return Extraction_Result
     renames Editor.Outline_Extractor.Scan_Engine.Extract;

   procedure Apply_To_Outline
     (Result  : Extraction_Result;
      Outline : in out Editor.Outline.Outline_State)
   is
   begin
      if not Editor.Outline.Snapshot_Is_Current
        (Outline, Result.Result_Identity)
      then
         Editor.Outline.Mark_Stale_Result (Outline);
         return;
      end if;

      if Result.Result_Status = Extraction_Failed then
         Editor.Outline.Mark_Extraction_Failed (Outline);
         return;
      elsif Result.Result_Status = Extraction_Unavailable then
         if Result.Result_Identity.Request_Token = 0 then
            return;
         end if;

         Editor.Outline.Mark_Unsupported (Outline);
         return;
      end if;

      if Item_Count (Result) = 0 then
         Editor.Outline.Mark_Unsupported
           (Outline, Editor.Outline.Message_Outline_No_Symbols);
      else
         declare
            Items : Editor.Outline.Outline_Item_Array (1 .. Item_Count (Result));
            J     : Positive := Items'First;
         begin
            for Item of Result.Items loop
               Items (J) := Item;
               J := J + 1;
            end loop;
            Editor.Outline.Replace_Items (Outline, Items);
         end;
      end if;
   end Apply_To_Outline;

end Editor.Outline_Extractor;
