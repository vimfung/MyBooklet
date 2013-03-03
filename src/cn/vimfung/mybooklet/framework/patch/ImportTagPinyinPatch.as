package cn.vimfung.mybooklet.framework.patch
{
	import cn.vimfung.mybooklet.framework.GNFacade;
	import cn.vimfung.mybooklet.framework.db.SqliteDatabaseToken;
	import cn.vimfung.mybooklet.framework.events.PatchEvent;
	import cn.vimfung.mybooklet.framework.events.SqliteDatabaseEvent;
	import cn.vimfung.gnotes.kit.ISystemManager;
	import cn.vimfung.utils.Chinese2Spell;
	import cn.vimfung.utils.SpellOptions;
	
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.Dictionary;
	
	/**
	 * 补丁成功 
	 */	
	[Event(name="patchSuccess", type="cn.vimfung.mybooklet.framework.events.PatchEvent")]
	
	/**
	 * 补丁失败 
	 */	
	[Event(name="patchFail", type="cn.vimfung.mybooklet.framework.events.PatchEvent")]
	
	/**
	 * 导入标签拼音数据补丁 
	 * @author Administrator
	 * 
	 * @since	ver1.3.0
	 * 
	 */	
	public class ImportTagPinyinPatch extends EventDispatcher implements IPatchObject
	{
		/**
		 * 命令名称 
		 */		
		public static const NAME:String = "928ED78CA62528B1";
		
		public function ImportTagPinyinPatch(target:IEventDispatcher=null)
		{
			super(target);
			
			_gnFacade = GNFacade.getInstance();
		}
		
		private var _gnFacade:GNFacade;
		
		/**
		 * @inheritDoc
		 * */
		public function start(system:ISystemManager):void
		{
			var token:SqliteDatabaseToken = _gnFacade.documentDatabase.createCommandToken("SELECT id,name FROM notes_tag");
			token.addEventListener(SqliteDatabaseEvent.RESULT, getTagListResultHandler);
			token.addEventListener(SqliteDatabaseEvent.ERROR, getTagListErrorHandler);
			token.start();
		}
		
		/**
		 * 获取标签列表返回 
		 * @param event 事件
		 * 
		 */		
		private function getTagListResultHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, getTagListResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, getTagListErrorHandler);
			
			if(event.recordset != null)
			{
				_gnFacade.documentDatabase.beginTrans();
				for (var i:int = 0; i < event.recordset.length; i++)
				{
					var tag:Object = event.recordset[i];
					var pinyin:String = Chinese2Spell.makeSpellCode(tag.name, 0);
					var fpinyin:String = Chinese2Spell.makeSpellCode(tag.name, SpellOptions.FirstLetterOnly);
					
					var params:Dictionary = new Dictionary();
					params[":pinyin"] = pinyin;
					params[":fpinyin"] = fpinyin;
					params[":id"] = tag.id;
					
					_gnFacade.documentDatabase.execute("UPDATE notes_tag SET pinyin = :pinyin, fpinyin = :fpinyin WHERE id = :id", params, true);
				}
				_gnFacade.documentDatabase.commitTrans();
			}
			var e:PatchEvent = new PatchEvent(PatchEvent.PATCH_SUCCESS);
			e.name = ImportTagPinyinPatch.NAME;
			this.dispatchEvent(e);
		}
		
		/**
		 * 获取标签列表失败 
		 * @param event 事件
		 * 
		 */		
		private function getTagListErrorHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, getTagListResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, getTagListErrorHandler);
			
			var e:PatchEvent = new PatchEvent(PatchEvent.PATCH_FAIL);
			e.error = event.error;
			this.dispatchEvent(e);
		}
	}
}