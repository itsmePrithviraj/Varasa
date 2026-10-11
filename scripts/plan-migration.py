#!/usr/bin/env python3
"""Offline plan only. Input: {users:[{id,...}],posts:[{id,...,comments:[]}]}.
No credentials or remote writes. Treat generated output as private account data.
"""
import argparse, datetime, hashlib, json, re
from pathlib import Path

def build_plan(source):
    documents, warnings, users, handles = {}, [], {}, set()
    def ident(value):
        return isinstance(value,str) and re.fullmatch(r'[A-Za-z0-9_-]{1,128}',value)
    def millis(value):
        if isinstance(value,dict) and 'seconds' in value: return int(value['seconds']*1000)
        if isinstance(value,(int,float)): return int(value)
        if isinstance(value,str):
            try:return int(datetime.datetime.fromisoformat(value.replace('Z','+00:00')).timestamp()*1000)
            except ValueError:pass
        warnings.append('A missing/invalid timestamp was assigned 0; review chronology.')
        return 0
    def public_url(value):
        return value if isinstance(value,str) and value.startswith('https://') else ''
    for old in source.get('users',[]):
        uid=old.get('id')
        if not ident(uid) or uid in users:raise ValueError('Invalid/duplicate user ID')
        raw=re.sub(r'[^a-z0-9_]','_',str(old.get('username','')).lower())[:30]
        handle=raw if len(raw)>=3 else 'member_'+hashlib.sha256(uid.encode()).hexdigest()[:16]
        if handle in handles:
            handle=handle[:18]+'_'+hashlib.sha256(uid.encode()).hexdigest()[:10]
            warnings.append(f'Duplicate handle renamed for user {uid}.')
        if handle in handles:raise ValueError('Handle collision; manual resolution required')
        handles.add(handle);users[uid]=old
        documents[f'profiles/{uid}']={'displayName':str(old.get('displayName',old.get('name','Member')))[:80],'username':handle,'username_lower':handle,'bio':str(old.get('bio',''))[:300],'photoUrl':public_url(old.get('photoUrl','')),'avatarPath':'','followersCount':0,'followingCount':0,'friendsCount':0,'suspended':False,'createdAtMs':millis(old.get('createdAt',old.get('timestamp')))}
        documents[f'accounts/{uid}']={'deleting':False,'createdAtMs':documents[f'profiles/{uid}']['createdAtMs']}
        documents[f'handles/{handle}']={'uid':uid}
    for uid,old in users.items():
        for target in set(old.get('following',[])):
            if target==uid or target not in users: warnings.append(f'Skipped unresolved follow from {uid}.');continue
            documents[f'profiles/{uid}/following/{target}']={'userId':target,'createdAtMs':0}
            documents[f'profiles/{target}/followers/{uid}']={'userId':uid,'createdAtMs':0}
            documents[f'profiles/{uid}']['followingCount']+=1;documents[f'profiles/{target}']['followersCount']+=1
    for old in source.get('posts',[]):
        pid,uid=old.get('id'),old.get('userId')
        if not ident(pid) or f'stories/{pid}' in documents:raise ValueError('Invalid/duplicate story ID')
        if uid not in users:warnings.append(f'Skipped story {pid}: author missing.');continue
        if old.get('deleted'):continue
        likes={v for v in old.get('likes',[]) if v in users}
        lat,lng=old.get('latitude'),old.get('longitude')
        if not(isinstance(lat,(float,int)) and isinstance(lng,(float,int)) and -90<=lat<=90 and -180<=lng<=180):lat=lng=None
        doc={'userId':uid,'username':documents[f'profiles/{uid}']['username'],'photoUrl':documents[f'profiles/{uid}']['photoUrl'],'authorAvatarPath':'','caption':str(old.get('caption',''))[:3000],'place':str(old.get('place',''))[:120],'latitude':lat,'longitude':lng,'imageUrl':public_url(old.get('imageUrl','')),'attachmentUrl':public_url(old.get('attachmentUrl','')),'attachmentName':str(old.get('attachmentName',''))[:200],'storagePath':'','likeCount':len(likes),'commentCount':0,'deleted':False,'moderated':False,'createdAtMs':millis(old.get('timestamp',old.get('createdAt')))}
        documents[f'stories/{pid}']=doc
        for member in likes:documents[f'stories/{pid}/likes/{member}']={'userId':member,'storyId':pid,'createdAtMs':0}
        for c in old.get('comments',[]):
            cid,author=c.get('id'),c.get('userId')
            if not ident(cid) or author not in users:warnings.append(f'Skipped unresolved comment in {pid}.');continue
            path=f'stories/{pid}/comments/{cid}'
            if path in documents:raise ValueError('Duplicate comment ID')
            documents[path]={'userId':author,'storyId':pid,'username':documents[f'profiles/{author}']['username'],'text':str(c.get('text',''))[:1000],'deleted':False,'createdAtMs':millis(c.get('timestamp'))};doc['commentCount']+=1
    warnings.extend(['Review every mapped field and handle before import. Private user fields are excluded.','Friends/requests need a reviewed legacy schema; they are not inferred from following.','Media URLs are references only. Copy/reconcile Storage objects separately before cutover.','Auth users must already exist in the destination with these exact UIDs. No passwords are exported.','Following histories are not precomputed by this plan. Following backfill or a reviewed feed rebuild is required.'])
    return {'schemaVersion':2,'documents':documents,'warnings':warnings}

def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('input');parser.add_argument('output');args=parser.parse_args()
    output=Path(args.output)
    if output.exists():raise SystemExit('Refusing to overwrite an existing plan.')
    plan=build_plan(json.loads(Path(args.input).read_text()));output.write_text(json.dumps(plan,indent=2)+'\n');output.chmod(0o600)
    print(f'Wrote {len(plan["documents"])} documents and {len(plan["warnings"])} review notes. No remote changes.')
if __name__=='__main__':main()
