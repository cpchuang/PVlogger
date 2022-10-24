import urllib, datetime
from bs4 import BeautifulSoup
import numpy as np

def get_group():
    """
    this function get Datagroup list, no input needed.
    
    Usage: 
        group_list = get_group()
    """
    
    # site and query info
    site = 'https://ops.aps.anl.gov/cgi-bin/oagMonitorDataReview.cgi'
    query = {'ListDataGroups': '1'}
    # constuct url
    url = f'{site}?{urllib.parse.urlencode(query)}'
    #print(url)
    
    # get the page
    resp = urllib.request.urlopen(url)
    the_page = resp.read()
    resp.close()
    # parse the page
    # see this page "https://www.crummy.com/software/BeautifulSoup/bs4/doc/#installing-a-parser" for parser selection
    soup= BeautifulSoup(the_page, 'lxml')
    # get Data_Group list
    group_list = soup.body.get_text().split()
    
    return group_list


def get_PVlist(datagroup):
    """
    this function get List of PVs under a specific DataGroup
    
    Usage:
        PV_list = get_PVlist(datagroup)
        datagroup must be a string
    """
    if not isinstance(datagroup,(list, tuple, str)):
        raise TypeError("Input must be a tuple or list or string")
    elif isinstance(datagroup,(list, tuple)) and len(datagroup)>1 :
        print('Input has more than one element, process only the first one!!')
        datagroup=datagroup[0]
    
    # site and query info
    site = 'https://ops.aps.anl.gov/cgi-bin/oagMonitorDataReview.cgi'
    query = {'DataGroup': datagroup,
             'ListReadbackNames': '1',}
    # constuct url
    url = f'{site}?{urllib.parse.urlencode(query)}'

    # get the page
    resp = urllib.request.urlopen(url)
    the_page = resp.read()
    resp.close()
    # parse the page
    # see this page "https://www.crummy.com/software/BeautifulSoup/bs4/doc/#installing-a-parser" for parser selection
    soup= BeautifulSoup(the_page, 'lxml')
    # get Data_Group list
    PV_list = soup.body.get_text().split()

    if not PV_list:
        print(f'The requested DataGroup "{datagroup}" does not exist!!')
    else:
        return PV_list

    
def get_PVdata(datagroup, pvlist, start_time='24', end_time='now'):
    """
    This function get PVdata of multiple PVs within the same datagroup
    
    Usage:
        header, data = get_PVdata(datagroup, pvlist, start_time='24', end_time='now')
        
         datagroup: datagroup name (str)
            pvlist: list of PV_name(ReadBackNames on Data Review website, not necessary PV_name)
        start_time: follow YYYY/MM/DD format, or 'h' for "h" hours before end_time. default: 24 (hours)
          end_time: follow YYYY/MM/DD format, or 'h' for "h" hours after start_time, or 'now'. default: 'now'
    """
    
    if not isinstance(datagroup,(list, tuple, str)):
        raise TypeError("Input must be a tuple or list or string")
    elif isinstance(datagroup,(list, tuple)) and len(datagroup)>1 :
        print('Input more than one DataGroup, query only the first one!!')
        datagroup=datagroup[0]        

    # get PVlist from Datagroup
    PVlist = get_PVlist(datagroup)
    #print(PVlist)
    
    print(pvlist)

    index_list = []
    if pvlist=='all':
        index_list = range(0,len(PVlist))
    else:
        for pv in pvlist:
            index_list.append(PVlist.index(pv))

    if end_time=='now':
        endtime  = datetime.datetime.now()
        endyear  = endtime.year
        endmonth = endtime.month
        endday   = endtime.day
        endhour  = endtime.hour
        if start_time.isdigit():
            #print(f'start_time is digit and is {start_time}')
            starttime=endtime-datetime.timedelta(hours=int(start_time))
        else:
            if len(start_time.split('/'))==2:
                start_time = f'{datetime.date.today().year}/'+start_time
            starttime = datetime.datetime.strptime(start_time,'%Y/%m/%d')

        startyear  = starttime.year
        startmonth = starttime.month
        startday   = starttime.day
        starthour  = 0
    else:
        if len(start_time.split('/'))==2:
            start_time = f'{datetime.date.today().year}/'+start_time
        starttime = datetime.datetime.strptime(start_time,'%Y/%m/%d')

        if end_time.isdigit():
            endtime=starttime+datetime.timedelta(hours=int(end_time))
        else:
            if len(end_time.split('/'))==2:
                end_time = f'{datetime.date.today().year}/'+end_time
            endtime = datetime.datetime.strptime(end_time,'%Y/%m/%d')

        startyear  = starttime.year
        startmonth = starttime.month
        startday   = starttime.day
        starthour  = 0
        endyear  = endtime.year
        endmonth = endtime.month
        endday   = endtime.day
        endhour  = endtime.hour
    #print(f'start date is {starttime}')
    #print(f'  end date is {endtime}')

    # site and query info
    site = 'https://ops.aps.anl.gov/cgi-bin/oagMonitorDataReview.cgi'

    query = {'DataGroup': datagroup,
             datagroup+'_ControlReadbackName': index_list,
            'ExportCSV': 'Export+Data+(CSV)',
            'StartYear':  startyear,
            'StartMonth': startmonth,
            'StartDay':   startday,
            'StartHour':  starthour,
            'EndYear':    endyear,
            'EndMonth':   endmonth,
            'EndDay':     endday,
            'EndHour':    endhour,}


    # constuct url
    url = f'{site}?{urllib.parse.urlencode(query,True)}'
    # need this freaking line to parse address correctly("+" & "()" sign)!! maybe there is a way to do it in erlencode() but I cannot figure it out!!
    url = urllib.parse.unquote_plus(url)
    print(url)

    resp = urllib.request.urlopen(url)
    #print(resp.status)

    # treat as a html page
    the_page = resp.read()
    soup= BeautifulSoup(the_page, 'lxml')
    resp.close()

    try:
        header = soup.title.get_text()
        if 'Error' in header:
            print(f'Respond: {header}')
            print(f'{soup.body.get_text()}')
            arr=None
        else:
            print(f'Undefined Respond: {header}')
            arr=None
    except:
        # title is None, so likely a text file
        print('Data download successfully...')
        body = soup.body.get_text().rstrip().split()
        header = body[1].split(',')
        arr=np.array([])
        for i in range(2,len(body)):
            da_=body[i].rstrip().split(',')
            if not da_[0]=='':   # skip empty line
                arr = np.append(arr, np.array(da_).astype('float'))
                # reshape array, now we have the data
                arr = np.reshape(arr,(-1,len(header)))   

    return header, arr

